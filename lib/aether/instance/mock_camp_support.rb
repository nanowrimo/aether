module Aether
  module Instance
    class MockCampSupport < Default
      self.type = "mock-camp-support"
      self.default_options = {:instance_type => "m1.large"}
    end
  end
end
