module Aether
  module Instance
    class Stressor < Default
      self.type = "stressor"
      self.default_options = {:instance_type => "c1.xlarge", :promote_by => :dns_alias}
    end
  end
end
