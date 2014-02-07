require 'shellwords'

module Aether
  class Shell
    class Sandbox
      SYSTEM_OPEN_COMMANDS = [ :'xdg-open', :open ]

      # Resolves the appropriate system command for opening URLs.
      #
      def self.system_open_command
        @system_open_command ||= self::SYSTEM_OPEN_COMMANDS.find { |cmd| `which #{cmd}`; $?.success? }
      end

      def initialize(connection)
        @connection = connection
      end

      # A shortcut to +Instance.find+.
      #
      def instance(id = nil)
        id ? Instance.find(id) : Instance
      end

      # A shortcut to +Instance.all+.
      #
      def instances
        Instance.all
      end

      # A terse abbreviation for accessing the current connection DNS. When
      # given a block, shortcut to +Dns#zone.where+.
      #
      def dns(&blk)
        block_given? ? @connection.dns.zone.where(&blk) : @connection.dns
      end

      # Instantiate and launch one or the given number of instances of +type+.
      # If a number is given, the array of instances is returned, otherwise
      # just the single instance.
      #
      def launch(type, n = nil)
        instances = (n || 1).times.collect { new(type).launch! }

        n ? instances : instances.first
      end

      # A shortcut to +Instance.new+.
      #
      def new(*arguments)
        Instance.new(*arguments)
      end

      # Opens the given resource or resources.
      #
      def open(*resources)
        resources.tap { open_url(*resources.flatten.collect(&:url)) }
      end

      # Opens the given URLs using a system-appropriate method. Currently,
      # only OS X and Linux are supported using `open` or `xdg-open`
      # respectively.
      #
      def open_url(*urls)
        urls.each { |url| `#{self.class.system_open_command} #{url.to_s.shellescape}` }
      end

      def snapshots
        Snapshot.all
      end

      # A shortcut to +Volume.find+.
      #
      def volume(id)
        Volume.find(id)
      end

      # A shortcut to +Volume.all+.
      #
      def volumes
        Volume.all
      end

      def method_missing(method, *args)
        super unless InstanceCollection.instance_methods.map(&:to_s).include?(method.to_s)
        Instance.all.send(method, *args)
      end
    end
  end
end
