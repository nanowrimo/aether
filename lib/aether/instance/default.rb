require 'net/ssh'
require 'net/sftp'
require 'uri'

module Aether
  module Instance
    class Default
      include Ec2Model
      extend Observable

      class << self
        attr_accessor :default_options, :type, :manage_dns

        def default_options=(options)
          if superclass.respond_to?(:default_options)
            @default_options = superclass.default_options.merge(options)
          else
            @default_options = options
          end
        end

        def type
          @type || 'default'
        end
      end

      self.default_options = {}

      after(:launch) do
        if @options[:configure_by] == :puppet
          wait_for { |instance| instance.running? && instance.ssh? }

          # Upload our SSH key-sharer key to newly launched instances
          ssh_key = File.expand_path("~/.aether/ssh_key_sharer")
          ssh_pub_key = "#{ssh_key}.pub"

          if File.exists?(ssh_key)
            notify 'uploading SSH key-sharer key'

            upload_to_directory!("/var/lib/puppet", ssh_key => 0400, ssh_pub_key => 0640)
          end

          # Prepend PATH environment variable with the Ruby gems binary path
          exec!("echo 'PATH=\"/var/lib/gems/1.8/bin:'\"$PATH\"'\"' >> /etc/environment")

          # Make sure that /mnt is mounted
          # TODO Clean this mess up
          device = volume_device('b')
          exec!(<<-end_exec)
            if [ -b '#{device}' ]; then
              cut -d ' ' -f 1 /proc/mounts | grep -q '#{device}' || mount '#{device}' /mnt
            fi
          end_exec
        end

        # Create canonical DNS record
        if manage_dns?
          wait_for { |instance| instance.running? }

          begin
            @dns_alias = create_dns_alias(name)
          rescue StandardError => e
            notify 'FAILED to create new DNS record', e
          end
        end
      end

      attr_reader :options, :info

      def initialize(options = {})
        @options = {
          :image_name => "base-debian-6",
          :instance_type => 'm1.small',
          :architecture => 'x86_64',
          :promote_by => :null,
          :configure_by => :puppet
        }.merge(self.class.default_options)

        @info = yield if block_given?
      end

      [:key_name, :availability_zone, :architecture, :instance_type, :image_name, :block_device_mapping].each do |attr|
        class_eval <<-end_class_eval
          def #{attr}
            @#{attr} || @options[:#{attr}] || @connection.options[:#{attr}]
          end
        end_class_eval
      end

      [:pending, :running, :shutting_down, :terminated, :stopping, :stopped].each do |state|
        class_eval <<-end_class_eval
          def #{state}?
            state == '#{state.to_s.gsub('_', '-')}'
          end
        end_class_eval
      end

      def attach_volumes!
        volumes.each { |volume| volume.attach_to!(self) }
      end

      def attached_volumes
        Volume.all(connection).attached_to(self)
      end

      def configure!(*args)
        notify 'configuring instance', self
        around_callback(:configure) { configurator.configure!(*args) }
      end

      def create_dns_alias(name, ttl = nil)
        assert_launched

        notify 'creating new DNS alias', name, ttl, @info.dnsName

        @connection.dns.create_alias(name, @info.dnsName, ttl)
      end

      def demote!(new_leader = nil)
        around_callback(:demotion, new_leader) { promoter.demote! }
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
        return nil unless manage_dns?
        @dns_alias ||= @connection.dns.aliases(name).first
      end

      def dns_name
        (dns_alias && dns_alias.name.chomp('.')) || ec2_dns_name
      end

      def ec2_dns_name
        @info && @info.dnsName
      end

      def exec!(*commands, &block)
        output = nil

        options = { :exit_statuses => [] }.merge((commands.last.is_a?(Hash) && commands.pop) || {})

        block ||= Proc.new { |output| notify output }

        exit_statuses = options[:exit_statuses] + [0]

        ssh(options[:ssh] || {}) do |session|
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

        image_id = @options[:image_id] || resolve_image

        parameters = {:image_id => image_id,
                      :instance_type => instance_type,
                      :security_group => security_group,
                      :availability_zone => availability_zone,
                      :key_name => key_name,
                      :block_device_mapping => block_device_mapping || []}

        notify 'running new instance', parameters

        around_callback(:launch, parameters) do
          around_callback(:run, parameters) do
            @info = @connection.run_instances(parameters).instancesSet.item.first
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

      def manage_dns?
        self.class.manage_dns || true
      end

      def name
        "#{type}-#{id[2,10]}"
      end

      def promote!
        around_callback(:promotion) { promoter.promote! }
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
        @options[:security_group] || self.class.type
      end

      def sftp(user = nil, options = {}, &blk)
        options = {:keys => @connection.options[:ssh_keys]}.merge(options)
        Net::SFTP.start(ec2_dns_name, user || @connection.options[:ssh_user] || 'root', options, &blk)
      end

      # Returns an ssh URL to the instance.
      #
      def url
        URI::Generic.build(:scheme => 'ssh', :userinfo => ssh_user, :host => ec2_dns_name)
      end

      # Returns the right block device path from the given name.
      #
      # If the running kernel uses 'xvd' device names, the result will be
      # '/dev/xvd#{name}', otherwise it will be a scsi device like
      # '/dev/sd#{name}'.
      #
      def volume_device(name)
        root_device.match(%r{/xvd}) ? "/dev/xvd#{name}" : "/dev/sd#{name}"
      end

      # Returns the block device path mounted at '/'.
      #
      def root_device
        @root_device ||= exec!("readlink -f /dev/root")
      end

      def ssh(options = {}, &blk)
        options = {
          :user => ssh_user,
          :keys => @connection.options[:ssh_keys]
        }.merge(options)

        Net::SSH.start(ec2_dns_name, options[:user], options, &blk)
      end

      def ssh?(*arguments)
        ssh(*arguments) { }
        true
      rescue Errno::ECONNREFUSED, Errno::ETIMEDOUT
        false
      end

      def ssh_user
        @connection.options[:ssh_user] || 'root'
      end

      def state
        assert_launched

        @info.instanceState.name
      end

      def terminate!(options = {})
        notify "terminating instance", id, name

        around_callback(:terminate) do
          @connection.terminate_instances(options.merge(:instance_id => id))
        end

        if manage_dns? && dns_alias
          notify "deleting DNS alias", dns_alias

          dns_alias.delete
        end
      end

      def to_s
        "#{name}\t#{state}\t#{launch_time}"
      end

      def type
        (@info && @info.group) || self.class.type || @options[:security_group]
      end

      def upload_to_directory!(directory, files_and_modes = {})
        sftp do |session|
          files_and_modes.map do |(path, mode)|
            notify 'uploading file to directory', path, directory

            [session.upload(path, "#{directory}/#{File.basename(path)}"), mode]
          end.each do |(upload,mode)|
            upload.wait

            notify 'setting mode', mode.to_s(8)

            session.setstat!(upload.remote, :permissions => mode)
          end
        end
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

        self
      end

      private

      def assert_launched
        raise UnlaunchedInstanceError unless launched?
      end

      def configurator
        InstanceConfigurator.new(@options[:configure_by], self)
      end

      def notify(*args)
        Aether::Instance::Default.changed
        Aether::Instance::Default.notify_observers(*args)
      end

      def promoter
        InstancePromoter.new(@options[:promote_by], self)
      end

      def resolve_image
        image = @connection.images.select{ |image| runs_on?(image) }.reduce do |newest,image|
          image.revision > newest.revision ? image : newest
        end

        raise StandardError.new("failed to resolve AMI") unless image

        image.imageId
      end

      def runs_on?(image)
        image_name == image.name && architecture == image.architecture
      end
    end
  end
end
