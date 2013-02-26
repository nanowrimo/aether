module Aether
  module Instance
    class MockCampSupport < Default
      def initialize(options = {})
        super("mock-camp-proxy", {:instance_type => "c1.medium"}.merge(options))
      end
    end
  end
end
