module Aether
  module Instance
    class Database < Default
      include InstanceHelpers::MetaDisk

      def initialize(options = {})
        super("database", {
          :instance_type => "m2.4xlarge",
          :image_name => "database-master",
          :availability_zone => 'us-east-1b',
          :configure_by => nil
        }.merge(options))
      end
    end
  end
end
