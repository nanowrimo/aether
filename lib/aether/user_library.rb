module Aether
  module UserLibrary
    def classify(name)
      name.to_s.gsub(/\/(.?)/) { "::#{$1.upcase}" }.gsub(/(?:^|_|-)(.)/) { $1.upcase }.to_sym
    end

    def constantize(sym)
      self.const_get(sym)
    end

    def load_path(*names)
      File.join(Aether.user_load_path, *names.map(&:to_s))
    end

    def require_user(*names)
      require load_path(*names)
      constantize(classify(names.last))
    end
  end
end
