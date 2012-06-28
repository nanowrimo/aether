module Aether
  module Instance
    class StoreWorker < Default
      def initialize(options = {})
        super("store-worker", {:instance_type => "m1.medium"}.merge(options))
      end
    end
  end
end
