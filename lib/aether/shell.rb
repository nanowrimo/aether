require 'ripl'

require 'aether/command'

module Aether

  # Starts a custom ripl shell for interactive access to an Aether connection.
  #
  class Shell < Command

    autoload :Sandbox, 'aether/shell/sandbox'

    # Initializes a new shell.
    #
    def initialize(options = {})
      super("shell", "[options]", options)

      @options[:key_name] = "cert"
      @option_parser.on("-k", "--key-name NAME", "The EC2 key-pair name to use.") do |name|
        @options[:key_name] = name
      end

      @options[:skip_dns] = false
      @option_parser.on(nil, "--skip-dns", "Don't interact with DNS.") do
        @options[:skip_dns] = true
      end

      # The shell is always a little verbose
      @options[:verbose] += 1 if @options[:verbose] < 1
    end

    # Starts the interactive shell.
    #
    def start
      Ripl.start :binding => Sandbox.new(@connection).instance_exec { binding },
                 :prompt => prompt
    end

    def prompt
      @options[:skip_dns] ? ">> " : proc { Connection.latest.dns.zone.name + ">> " }
    end

    # Evaluates a single command in the context of the shell and outputs the
    # result.
    #
    def evaluate(*command)
      Sandbox.new(@connection).instance_eval(command.join(' '))
    end
  end
end
