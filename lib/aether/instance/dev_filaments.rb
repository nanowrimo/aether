module Aether
  module Instance
    class DevFilaments < Default
      def initialize(options = {})
        super("dev-filaments", {
          :instance_type => "m1.medium",
          :promote_by => :dns_alias
        }.merge(options))
      end
    end
  end
end
