require 'aether/instance_promoter/base'

module Aether
  module InstancePromoter
    class Null < Base
      def demote!
      end

      def promote!
      end
    end
  end
end
