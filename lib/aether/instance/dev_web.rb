module Aether
  module Instance
    class DevWeb < Default
      def initialize(options = {})
        super("dev-web", {
          :image_name => "base",
          :instance_type => "c1.medium"
        }.merge(options))
      end
    end
  end
end
