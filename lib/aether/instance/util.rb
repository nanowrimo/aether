module Aether
  module Instance
    class Util < Default
      def initialize(options = {})
        super("util", {:instance_type => "c1.medium", :image_name => "util", :availability_zone => 'us-east-1b'}.merge(options))
      end
    end
  end
end
