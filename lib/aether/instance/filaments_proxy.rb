module Aether
  module Instance
    class FilamentsProxy < DebianWheezy
      self.type = "filaments-proxy"
      self.default_options = {:instance_type => "c1.medium", :promote_by => :dns_alias}
    end
  end
end
