require 'aether/command'

module Aether

  # Launches a new instance and provisions any dependent resources.
  #
  class Launcher < Command

    # Initializes a new launcher.
    #
    def initialize(options = {})
      super("launch", "[options] TYPE", options)

      @options[:key_name] = "cert"
      @option_parser.on("-k", "--key-name NAME", "The EC2 key-pair name to use.") do |name|
        @options[:key_name] = name
      end
    end

    # Launches a new instance of the given type.
    #
    def launch(type)
      Instance.new(type).launch!
    end
  end
end
