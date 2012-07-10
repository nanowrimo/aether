module Aether
  module InstanceConfigurator
    class Base
      attr_reader :instance

      def initialize(instance)
        @instance = instance
      end

      # Should implement instance configuration.
      #
      def configure!
      end
    end
  end
end
