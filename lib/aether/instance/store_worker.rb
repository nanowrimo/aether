module Aether
  module Instance
    class StoreWorker < Default

      after(:launch) do
        # reconfigure store instance to update nfs permissions, etc.
        Instance.all.running.in('store').each(&:configure!)
      end

      def initialize(options = {})
        super("store-worker", {:image_name => "base", :instance_type => "c1.medium"}.merge(options))
      end
    end
  end
end
