require 'aether/connection'

require 'optparse'
require 'observer'

module Aether
  class Command
    include Observable

    # Initialize a command with its usage and default options.
    #
    def initialize(name, usage, options = {})
      @name = name

      @options = options
      @option_parser = OptionParser.new do |parser|
        parser.banner = "Usage: ae-#{name} #{usage}"

        @options[:config] ||= File.expand_path("~/.aether/config.yml")
        parser.on("--config FILE", "A file containing default command options.") do |path|
          @options[:config] = path
        end

        @options[:access_key] ||= "/mnt/access.key"
        parser.on("-a", "--access-key FILE", "A file containing the AWS access key.") do |path|
          @options[:access_key] = path
        end

        @options[:secret_key] ||= "/mnt/secret.key"
        parser.on("-s", "--secret-key FILE", "A file containing the AWS secret key.") do |path|
          @options[:secret_key] = path
        end

        @options[:dns_zone] ||= "aether.lettersandlight.org"
        parser.on("-z", "--dns-zone ZONE", "The DNS zone in which instances live.") do |zone|
          @options[:dns_zone] = zone
        end

        @options[:dns_ttl] ||= "300"
        parser.on("--dns-ttl TTL", "The default DNS TTL to use when creating records.") do |ttl|
          @options[:dns_ttl] = ttl
        end

        @options[:cache_file] ||= nil
        parser.on("-c", "--cache-file FILE", "A file for caching instance data.") do |path|
          @options[:cache_file] = path
        end

        @options[:cache_life] ||= nil
        parser.on("-l", "--cache-life SECONDS", "The cache life in seconds.") do |seconds|
          @options[:cache_life] = seconds.to_i
        end

        @options[:ssh_user] ||= 'root'
        parser.on("-u", "--ssh-user USER", "User to use when starting SSH sessions.") do |user|
          @options[:ssh_user] = user
        end

        @options[:ssh_keys] ||= []
        parser.on("-i", "--ssh-key PATH", "SSH identity file to try when connecting.") do |path|
          @options[:ssh_keys].push(path)
        end

        @options[:verbose] ||= 0
        parser.on("-v", "--verbose", "Describe what's going on.") do
          @options[:verbose] += 1
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
      @config = Config.load(File.new(File.expand_path(@options[:config])))
      @options.merge!(@config.options_for(@name))

      @option_parser.parse!

      @options[:access_key] = File.new(File.expand_path(@options[:access_key])).gets.chomp
      @options[:secret_key] = File.new(File.expand_path(@options[:secret_key])).gets.chomp

      @options[:ssh_keys].map! { |path| File.expand_path(path) }
    end

    # Runs the command using the given method and the given arguments.
    #
    def run(method, args = nil)
      parse_options!
      connect!
      verbose! if @options[:verbose] > 0

      args ||= ARGV
      send(method, *args)

    rescue ArgumentError => e
      puts @option_parser.banner
      raise e
    rescue AWS::AuthFailure => e
      puts "Access denied. Please provide the right keys as options."
      puts
      puts @option_parser
      exit 2
    end

    # Be verbose.
    #
    def verbose!
      @notifier = Notifier.new(@options[:verbose])
      add_observer(@notifier)
      @connection.add_observer(@notifier) if @connection
      Instance::Default.add_observer(@notifier)
    end

    protected

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
