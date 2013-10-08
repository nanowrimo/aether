module Aether
  module Instance
    class DevFilamentsSupport < Default
      self.type = "dev-filaments-support"
      self.default_options = {:instance_type => "m1.large", :promote_by => :dns_alias}
    end
  end
end
