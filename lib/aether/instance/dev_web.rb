module Aether
  module Instance
    class DevWeb < Default
      def initialize(options = {})
        super("dev-web", {
          :image_name => "dev-web",
          :instance_type => "c1.medium",
          :configure_by => nil
        }.merge(options))
      end
    end
  end
end
