module Aether
  module Instance
    class Filaments < Default
      def initialize(options = {})
        super("filaments", {:instance_type => "m1.medium"}.merge(options))
      end
    end
  end
end
