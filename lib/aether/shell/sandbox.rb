module Aether
  class Shell
    class Sandbox

      def initialize(connection)
        @connection = connection
      end

      # A shortcut to +Instance.find+.
      #
      def instance(id = nil)
        (id && Instance.find(id)) || Instance
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
    end
  end
end
