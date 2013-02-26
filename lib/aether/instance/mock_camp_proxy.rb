module Aether
  module Instance
    class MockCampProxy < Default
      self.type = "mock-camp-proxy"
      self.default_options = {:instance_type => "c1.medium"}
    end
  end
end
