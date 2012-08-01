module Aether
  module Instance
    class Camp < Default
      def initialize(options = {})
        super("camp", {:instance_type => "m1.medium"}.merge(options))
      end
    end
  end
end
