module Aether
  module Instance
    class DevFilaments < Default
      def initialize(options = {})
        super("dev-filaments", {:instance_type => "m1.medium"}.merge(options))
      end
    end
  end
end
