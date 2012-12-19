module Aether
  module Instance
    class DatabaseSlave < Default
      include InstanceHelpers::MetaDisk

      def initialize(options = {})
        super("database-slave", {
          :instance_type => "m2.4xlarge",
          :image_name => "database-slave",
          :availability_zone => 'us-east-1b',
          :configure_by => nil
        }.merge(options))
      end
    end
  end
end
