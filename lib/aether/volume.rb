module Aether
  class Volume
    include Ec2Model
    extend Observable

    class << self
      def all(connection = nil)
        connection ||= Connection.latest
        connection.describe_volumes.volumeSet.item.map { |info| Volume.new { info } }
      end
    end

    def initialize(options = {})
      @options = options
      @info = yield if block_given?
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

    def launched?
      not @info.nil?
    end


    def id
      @info && @info.volumeId
    end

    def instance
      @info && Instance.find(@info.instanceId)
    end

    private

    def notify(*args)
      Aether::Instance::Default.changed
      Aether::Instance::Default.notify_observers(*args)
    end
  end
end
