module Aether
  module InstancePromoter
    class Base
      attr_reader :instance

      def initialize(instance)
        @instance = instance
      end

      # The current aether connection.
      #
      def connection
        instance.connection
      end

      # Should implement instance demotion.
      #
      def demote!
        raise NotImplementedError
      end

      # Should return the current instance leader, previously promoted.
      #
      def leader
        raise NotImplementedError
      end

      # Should implement instance promotion.
      #
      def promote!
        raise NotImplementedError
      end
    end
  end
end
