module Aether
  class Config
    class << self
      def from_file(path)
        full_path = File.expand_path(path)
        File.exist?(full_path) ? load(File.new(full_path)) : new
      end

      def load(io)
        new(YAML.load(io))
      end
    end

    def initialize(options = {})
      @options = options
    end

    def options_for(command)
      normalize_options(@options['default']).merge(normalize_options(@options[command.to_s]))
    end

    private

    def normalize_options(options)
      options.is_a?(Hash) ? options.inject({}) { |opts,(k,v)| opts[k.to_sym] = v; opts } : {}
    end
  end
end
