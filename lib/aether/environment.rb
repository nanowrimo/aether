module Aether
  module Environment
    autoload :Base, 'aether/environment/base'

    class << self
      include UserLibrary

      # Instantiates an environment of the given type.
      #
      def new(type)
        require_user(:environment, type).new(type)
      end
    end
  end
end
