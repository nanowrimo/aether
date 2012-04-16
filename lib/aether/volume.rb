module Aether
  class Volume
    include Ec2Model
    extend Observable

    has_ec2_options(:availability_zone, :size, :snapshot_id)

    class << self
      def all(connection = nil)
        connection ||= Connection.latest
        connection.describe_volumes.volumeSet.item.map do |info|
          volume = Volume.new { info }
          volume.connection = connection
          volume
        end.extend(VolumeCollection)
      end
    end

    def initialize(options = {})
      @options = {:size => 2}.merge(options)
      @info = block_given? ? yield : {}
    end

    def attached?
      status == 'in-use' && attachment
    end

    def attached_to?(instance_id)
      instance_id = instance_id.id if instance_id.is_a?(Instance::Default)
      attached? && attachment.instanceId == instance_id
    end

    def attachment
      @info['attachmentSet'] && @info['attachmentSet'].item.first
    end

    def create!
      raise StandardError.new("this volumes has already been created") if created?

      parameters = {:image_id => @image.imageId,
                    :instance_type => instance_type,
                    :security_group => security_group,
                    :availability_zone => availability_zone,
                    :key_name => key_name}

      notify 'creating new instance', parameters

      @info = @connection.run_instances(parameters).instancesSet.item.first

      wait_for { |instance| instance.info.dnsName }

      if @manage_dns
        begin
          notify 'creating new DNS alias', name, @info.dnsName

          @dns_alias = @connection.dns.create_alias(name, @info.dnsName)
        rescue StandardError => e
          notify 'FAILED to create new DNS record', e
        end
      end

      self
    end

    def created?
      not @info.empty?
    end

    def detach!
      notify 'detaching volume', self

      @connection.detach_volume(:volume_id => id)
    end

    def for?(instance_name)
      name_parts.first == instance_name
    end

    def id
      volume_id
    end

    def inspect
      if created?
        if tags["Name"]
          "#<vol:#{id}:#{size}:#{availability_zone}:#{status}:#{tags["Name"]}>"
        else
          "#<vol:#{id}:#{size}:#{availability_zone}:#{status}>"
        end
      else
        "#<vol:(new):#{size}:#{availability_zone}>"
      end
    end

    def instance
      attached? ? @instance ||= Instance.find(attachment.instanceId) : nil
    end

    def mount_point
      name_parts[1]
    end

    def name
      tags['Name']
    end

    def raid_member?
      raid_position
    end

    def raid_position
      name_parts[2] && name_parts[2].to_i
    end

    def status
      @info['status']
    end

    def tags
      if @info.tagSet
        @info.tagSet.item.inject({}) { |tags,tag| tags[tag.key] = tag.value; tags }
      else
        {}
      end
    end

    def to_s
      "#{name}\t#{state}\t#{launch_time}"
    end

    private

    def name_parts
      name ? name.split(':') : []
    end

    def notify(*args)
      Aether::Volume.changed
      Aether::Volume.notify_observers(*args)
    end
  end
end
