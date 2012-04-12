module Aether
  class Shell
    class Sandbox

      def initialize(connection)
        @connection = connection
      end

      # A shortcut to +Instance.find+.
      #
      def instance(id)
        Instance.find(id)
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

    end
  end
end
