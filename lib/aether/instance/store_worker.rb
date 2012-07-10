module Aether
  module Instance
    class StoreWorker < Default
      def initialize(options = {})
        super("store-worker", {:image_name => "base", :instance_type => "c1.medium"}.merge(options))
      end
    end
  end
end
