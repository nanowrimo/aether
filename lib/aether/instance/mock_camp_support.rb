module Aether
  module Instance
    class MockCampSupport < Default
      def initialize(options = {})
        super("mock-camp-support", {:instance_type => "m1.large"}.merge(options))
      end
    end
  end
end
