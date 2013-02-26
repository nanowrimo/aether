module Aether
  module Instance
    class FilamentsWorker < Default
      self.type = "filaments-worker"
      self.default_options = {:instance_type => "m1.medium"}
    end
  end
end
