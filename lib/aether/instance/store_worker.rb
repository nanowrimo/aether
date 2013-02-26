module Aether
  module Instance
    class StoreWorker < Default
      self.type = "store-worker"
      self.default_options = {:image_name => "base", :instance_type => "c1.medium"}

      after(:launch) do
        # reconfigure store instance to update nfs permissions, etc.
        Instance.all.running.in('store').each(&:configure!)
      end
    end
  end
end
