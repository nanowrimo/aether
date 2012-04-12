module Aether
  module Instance
    class Default
      include Ec2Model
      extend Observable

      attr_reader :type, :options, :info

      attr_accessor :connection

      def initialize(type, options = {})
        @type = type
        @options = {:image_name => "base-debian-6"}.merge(options)
        @info = yield if block_given?

        @manage_dns = true
      end

      def inspect
        if launched?
          "#<ins:#{type}:#{instance_id}:#{state}>"
        else
          "#<ins:#{type}:(new)>"
        end
      end

      [:key_name, :availability_zone, :instance_type, :image_name].each do |attr|
        class_eval <<-end_class_eval
          def #{attr}
            @#{attr} || @options[:#{attr}] || connection.options[:#{attr}]
          end
        end_class_eval
      end

      def architecture
        ARCHITECTURES[instance_type]
      end

      def dns_alias
        return nil unless @manage_dns
        @dns_alias ||= @connection.dns.aliases(name).first
      end

      def dns_name
        (dns_alias && dns_alias.name.chomp('.')) || (@info && @info.dnsName)
      end

      def id
        instance_id
      end

      def launch!
        raise StandardError.new("this instance has already been launched") if launched?

        resolve_image or raise StandardError.new("failed to resolve proper AMI")

        parameters = {:image_id => @image.imageId,
                      :instance_type => instance_type,
                      :security_group => security_group,
                      :availability_zone => availability_zone,
                      :key_name => key_name}

        notify 'running new instance', parameters

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

      def launched?
        not @info.nil?
      end

      def launch_time
        @info && Time.parse(@info.launchTime)
      end

      def name
        "#{type}-#{id[2,10]}"
      end

      def refresh!
        result = @connection.describe_instances(:instance_id => id)
        @info = result && result.reservationSet.item.first.instancesSet.item.first
        self
      end

      def security_group
        @options[:security_group] || @type
      end

      def state
        @info && @info.instanceState.name
      end

      def terminate!
        notify "terminating instance", id, name

        @connection.terminate_instances(:instance_id => id)

        if @manage_dns && dns_alias
          notify "deleting DNS alias", dns_alias

          dns_alias.delete
        end
      end

      def to_s
        "#{name}\t#{state}\t#{launch_time}"
      end

      def type
        @type || @options[:security_group]
      end

      def wait_for
        notify "waiting on instance #{id}"

        until yield self
          notify '...'
          sleep 3
          refresh!
        end
      end

      private

      def notify(*args)
        Aether::Instance::Default.changed
        Aether::Instance::Default.notify_observers(*args)
      end

      def resolve_image
        @image = @connection.images.select{ |image| runs_on?(image) }.reduce do |newest,image|
          image.revision > newest.revision ? image : newest
        end
      end

      def runs_on?(image)
        image_name == image.name && architecture == image.architecture
      end
    end
  end
end
