module Aether
  module Instance
    class MockCampSupport < Default
      self.type = "mock-camp-support"
      self.default_options = {:instance_type => "m1.large", :promote_by => :dns_alias}
    end
  end
end
