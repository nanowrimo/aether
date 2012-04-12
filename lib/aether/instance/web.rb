module Aether
  module Instance
    class Web < Default
      def initialize(options = {})
        super("web", {:instance_type => "c1.medium", :image_name => "web"}.merge(options))

        @manage_dns = false
      end
    end
  end
end
