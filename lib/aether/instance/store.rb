module Aether
  module Instance
    class Store < Default
      self.type = "store"
      self.default_options = {:instance_type => "c1.medium"}
    end
  end
end
