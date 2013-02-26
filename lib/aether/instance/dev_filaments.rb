module Aether
  module Instance
    class DevFilaments < Default
      self.type = "dev-filaments"
      self.default_options = {
        :instance_type => "m1.medium",
        :promote_by => :dns_alias
      }
    end
  end
end
