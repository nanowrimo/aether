module Aether
  module Instance
    class MockDatabase < Database
      self.type = "mock-database"
      self.default_options = Database.default_options.merge(:promote_by => :dns_alias)
    end
  end
end
