module Aether
  module Instance
    class MockCamp < Default
      self.type = "mock-camp"
      self.default_options = {:instance_type => "m1.medium"}
    end
  end
end
