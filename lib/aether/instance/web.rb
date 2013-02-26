module Aether
  module Instance
    class Web < Default
      self.type = "web"
      self.default_options = {
        :instance_type => "c1.medium",
        :image_name => "web",
        :configure_by => nil
      }
      self.manage_dns = false
    end
  end
end
