require 'aether/connection'

require 'optparse'
require 'observer'

module Aether
  class Command
    include Observable

    # Initialize a command with its usage and default options.
    #
    def initialize(usage, options = {})
      @options = options
      @option_parser = OptionParser.new do |parser|
        parser.banner = "Usage: #{usage}"

        @options[:access_key] = "/mnt/access.key"
        parser.on("-a", "--access-key FILE", "A file containing the AWS access key.") do |file|
          @options[:access_key] = file
        end

        @options[:secret_key] = "/mnt/secret.key"
        parser.on("-s", "--secret-key FILE", "A file containing the AWS secret key.") do |file|
          @options[:secret_key] = file
        end

        @options[:cache_file] = nil
        parser.on("-c", "--cache-file FILE", "A file for caching instance data.") do |file|
          @options[:cache_file] = file
        end

        @options[:cache_life] = nil
        parser.on("-l", "--cache-life SECONDS", "The cache life in seconds.") do |seconds|
          @options[:cache_life] = seconds.to_i
        end

        @options[:verbose] = false
        parser.on("-v", "--verbose", "Describe what's going on.") do
          @options[:verbose] = true
        end

        parser.on_tail("-h", "--help", "Show this message.") do
          puts parser
          exit
        end
      end
    end

    # Instantiates a connection using the supplied options.
    def connect!
      @connection ||= Connection.new(@options)
    end

    # Parse the command line options.
    #
    def parse_options!
      @option_parser.parse!

      @options[:access_key] = File.new(@options[:access_key])
      @options[:secret_key] = File.new(@options[:secret_key])
    end

    # Runs the command using the given method and the given arguments.
    #
    def run(method, args = nil)
      parse_options!
      connect!
      verbose! if @options[:verbose]

      args ||= ARGV
      send(method, *args)

    rescue ArgumentError
      puts @option_parser.banner
      exit 1
    rescue AWS::AuthFailure => e
      puts "Access denied. Please provide the right keys as options."
      puts
      puts @option_parser
      exit 2
    end

    # Be verbose.
    #
    def verbose!
      @notifier = Notifier.new
      add_observer(@notifier)
      @connection.add_observer(@notifier) if @connection
    end

    private

    # Formulates a unique name for the given instance that we use on our
    # Aether network.
    #
    def aether_name(instance)
      "#{instance.group}-#{instance.instanceId[2,10]}"
    end

    def notify(*args)
      changed
      notify_observers(*args)
    end
  end
end
