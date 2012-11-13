module Aether
  module Instance
    class FilamentsWorker < Default
      def initialize(options = {})
        super("filaments-worker", {:instance_type => "m1.medium"}.merge(options))
      end
    end
  end
end
