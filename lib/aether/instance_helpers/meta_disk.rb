module Aether
  module InstanceHelpers
    module MetaDisk
      def meta_disk_devices
        Aether::MetaDisk.scan(self)
      end
    end
  end
end
