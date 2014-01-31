module Aether
  module UserLibrary
    def classify(name)
      name.to_s.gsub(/\/(.?)/) { "::#{$1.upcase}" }.gsub(/(?:^|_|-)(.)/) { $1.upcase }.to_sym
    end

    def constantize(sym)
      user_namespace.const_get(sym)
    end

    def load_path(*names)
      File.join(Aether.user_load_path, *names.map { |name| name.to_s.gsub('-', '_') })
    end

    def user_file(*names)
      File.new(load_path(*names))
    end

    def user_namespace
      Object.const_get(Aether.user_namespace)
    rescue NameError
      Object.const_set(Aether.user_namespace, Module.new)
    end

    def require_user(*names)
      user_namespace
      require load_path(*names)
      constantize(classify(names.last))
    end
  end
end
