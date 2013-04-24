module Aether
  class Volume
    include Ec2Model
    extend Observable

    class AttachmentError < StandardError; end

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

      def device_names
        ('h'..'zz')
      end
    end

    def initialize(options = {})
      @options = {:size => 2}.merge(options)
      @info = block_given? ? yield : {}
    end

    def attach!(options)
      notify 'attaching volume', options

      @connection.attach_volume(options.merge(:volume_id => id))
    end

    def attach_to!(instance)
      raise AttachmentError unless for?(instance)
      attach!(:instance_id => instance.id, :device => device_for(instance))
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

    def available?
      status == 'available'
    end

    def create!
      raise StandardError.new("this volumes has already been created") if created?

      # TODO
      raise NotImplementedError

      self
    end

    def created?
      not @info.empty?
    end

    def detach!(options = {})
      notify 'detaching volume', self

      @connection.detach_volume(options.merge(:volume_id => id))
    end

    def device
      attachment.device if attachment
    end

    def device_for(instance)
      attached = instance.attached_volumes

      Volume.device_names.map { |name| instance.volume_device(name) }.detect do |device|
        not attached.any? { |volume| volume.device == device }
      end
    end

    def for?(instance)
      instance_type == (instance.is_a?(Instance::Default) ? instance.type : instance)
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

    def instance_type
      name_parts.first
    end

    def mount_device_for(instance)
      notify 'resolving mount device for', id, name, instance

      if mp = mount_point
        devs = instance.exec!("awk '$1 !~ /^#/ && $2 == \"#{mp}\" { print $1 }' /etc/fstab").split
        raise StandardError.new("failed to resolve device for volume") if devs.empty?
        devs.first
      end
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

    def refresh!
      @info = connection.describe_volumes(:volume_id => id).volumeSet.item.first
      self
    end

    def sibling?(volume)
      volume.instance_type == instance_type && volume.mount_point == mount_point && raid_position != volume.raid_position
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
      if created?
        if name
          "#{id}\t#{size}G\t#{status}\t#{name}"
        else
          "#{id}\t#{size}G\t#{status}\t#{name}"
        end
      else
        "(new)\t#{size}G"
      end
    end

    def wait_for
      notify "waiting on volume #{id}"

      until yield self
        notify '...'
        sleep 3
        refresh!
      end
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
