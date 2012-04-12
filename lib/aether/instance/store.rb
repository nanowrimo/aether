module Aether
  module Instance
    class Store < Default
      def initialize(options = {})
        super("store", {:instance_type => "c1.medium"}.merge(options))
      end
    end
  end
end
