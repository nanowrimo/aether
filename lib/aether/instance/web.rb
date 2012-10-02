module Aether
  module Instance
    class Web < Default
      def initialize(options = {})
        super("web", {
          :instance_type => "c1.medium",
          :image_name => "web",
          :configure_by => nil
        }.merge(options))

        @manage_dns = false
      end
    end
  end
end
