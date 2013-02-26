module Aether
  module Instance
    class MockCamp < Default
      def initialize(options = {})
        super("mock-camp", {:instance_type => "m1.medium"}.merge(options))
      end
    end
  end
end
