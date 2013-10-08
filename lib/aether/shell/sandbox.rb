require 'shellwords'

module Aether
  class Shell
    class Sandbox

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
      # given a block, shortcut to +Dns#where+.
      #
      def dns(&blk)
        block_given? ? @connection.dns.where(&blk) : @connection.dns
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

      # Opens the given resource or resources. Currently only supported in OS
      # X (using the `open` command).
      #
      def open(*resources)
        resources.tap { open_url(*resources.flatten.collect(&:url)) }
      end

      def open_url(*urls)
        `open #{urls.map(&:to_s).map(&:shellescape).join(' ')}`
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
