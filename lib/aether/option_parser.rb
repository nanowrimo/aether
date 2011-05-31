require 'optparse'

module Aether
  class Command
    def initialize(usage)
      super

      self.banner = "Usage: ae-puppet-classfifier [options] HOST"

      options[:access_key] = "/mnt/access.key"
      parser.on("-a", "--access-key FILE", "A file containing the AWS access key.") do |file|
        options[:access_key] = file
      end

      options[:secret_key] = "/mnt/secret.key"
      parser.on("-s", "--secret-key FILE", "A file containing the AWS secret key.") do |file|
        options[:secret_key] = file
      end

      options[:cache_file] = nil
      parser.on("-c", "--cache-file FILE", "A file for caching instance data.") do |file|
        options[:cache_file] = file
      end

      options[:cache_life] = nil
      parser.on("-l", "--cache-life SECONDS", "The cache life in seconds.") do |seconds|
        options[:cache_life] = seconds.to_i
      end

      options[:verbose] = false
      parser.on("-v", "--verbose", "Describe what's going on.") do
        options[:verbose] = true
      end

      parser.on_tail("-h", "--help", "Show this message.") do
        puts parser
        exit
      end
    end
  end
end
