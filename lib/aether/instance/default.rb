require 'net/ssh'

module Aether
  module Instance
    class Default
      include Ec2Model
      extend Observable

      attr_reader :type, :options, :info

      def initialize(type, options = {})
        @type = type
        @options = {:image_name => "base-debian-6", :promote_by => :null}.merge(options)
        @info = yield if block_given?

        @promoter = InstancePromoter.new(@options[:promote_by], self)

        @manage_dns = true
      end

      def ==(other)
        other.is_a?(::Aether::Instance::Default) && other.id == id
      end

      [:key_name, :availability_zone, :instance_type, :image_name].each do |attr|
        class_eval <<-end_class_eval
          def #{attr}
            @#{attr} || @options[:#{attr}] || @connection.options[:#{attr}]
          end
        end_class_eval
      end

      def architecture
        ARCHITECTURES[instance_type]
      end

      def attach_volumes!
        volumes.each { |volume| volume.attach_to!(self) }
      end

      def attached_volumes
        Volume.all(connection).attached_to(self)
      end

      def create_dns_alias(name)
        assert_launched

        notify 'creating new DNS alias', name, @info.dnsName

        @connection.dns.create_alias(name, @info.dnsName)
      end

      def demote!(new_leader = nil)
        around_callback(:demotion, new_leader) { @promoter.demote! }
      end

      def detach_volumes!
        attached_volumes.each(&:detach!)
      end

      def file_exists?(path)
        exec!("[ -e '#{path}' ]")
      rescue RemoteExecutionError => e
        raise e unless e.exit_status == 1
        false
      else
        true
      end

      def dns_alias
        return nil unless @manage_dns
        @dns_alias ||= @connection.dns.aliases(name).first
      end

      def dns_name
        (dns_alias && dns_alias.name.chomp('.')) || (@info && @info.dnsName)
      end

      def exec!(*commands, &block)
        output = nil

        options = { :exit_statuses => [] }.merge((commands.last.is_a?(Hash) && commands.pop) || {})

        block ||= Proc.new { |output| notify output }

        exit_statuses = options[:exit_statuses] + [0]

        ssh do |session|
          output = commands.collect do |cmd|
            out = ""
            err = ""
            code = nil

            session.open_channel do |ch|
              ch.exec(cmd) do |ch,success|
                raise RemoteExecutionError.new(cmd) unless success

                ch.on_data do |ch,data|
                  block.call(data) if block
                  out += data
                end

                ch.on_extended_data do |ch,type,data|
                  block.call(data) if block
                  err += data
                end

                ch.on_request("exit-status") do |ch,data|
                  code = data.read_long
                end
              end
            end

            session.loop

            raise RemoteExecutionError.new(cmd, err, code) if code && !exit_statuses.include?(code)

            out
          end.join
        end

        output
      end

      def id
        instance_id
      end

      def inspect
        if launched?
          "#<ins:#{type}:#{instance_id}:#{state}>"
        else
          "#<ins:#{type}:(new)>"
        end
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
            @dns_alias = create_dns_alias(name)
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
        assert_launched

        Time.parse(@info.launchTime)
      end

      def name
        "#{type}-#{id[2,10]}"
      end

      def promote!
        around_callback(:promotion) { @promoter.promote! }
      end

      def reboot!(options = {})
        notify "rebooting instance", id, name

        @connection.reboot_instances(options.merge(:instance_id => id))
      end

      def refresh!
        @info = (result = @connection.load_instances(:instance_id => id).first) && result.last
        self
      end

      def security_group
        @options[:security_group] || @type
      end

      def ssh(user = nil, options = {}, &blk)
        options = {:keys => @connection.options[:ssh_keys]}.merge(options)
        Net::SSH.start(dns_name, @connection.options[:ssh_user] || 'root', options, &blk)
      end

      def state
        assert_launched

        @info.instanceState.name
      end

      def terminate!(options = {})
        notify "terminating instance", id, name

        @connection.terminate_instances(options.merge(:instance_id => id))

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

      def volumes
        Volume.all(connection).for(self)
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

      def assert_launched
        raise UnlaunchedInstanceError unless launched?
      end

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
