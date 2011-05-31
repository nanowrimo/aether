require 'AWS'
require 'observer'
require 'tempfile'
require 'yaml'

module Aether
  IMAGE_PATTERN = %r{^[^/]+/oll-(.+)(?:-(?:32|64)bit)?-r([0-9]+)\.manifest\.xml$}

  class Connection
    include Observable

    class << self
      attr_accessor :latest

      def new(*args)
        self.latest = super(*args)
      end
    end

    attr_accessor :access_key, :secret_key
    attr_reader :options

    def initialize(options = {})
      [:access_key, :secret_key].each do |key|
        self.send("#{key}=", options[key].is_a?(IO) ? options[key].gets.chomp : options[key])
      end

      @ec2 = AWS::EC2::Base.new(:access_key_id => access_key,
                                :secret_access_key => secret_key)

      @cache_file = options[:cache_file] || default_cache_file
      @cache_life = options[:cache_life] || (4 * 60)

      @options = {
        :availability_zone => "us-east-1b",
      }.merge(options)
    end

    # Returns all AMI information.
    #
    def images
      @ec2.describe_images(:owner_id => "self").imagesSet.item.inject([]) do |images,i|
        name, rev = i.imageLocation.gsub(IMAGE_PATTERN) { [$1, $2] }
        i["name"] = name
        i["revision"] = rev
        images << i
      end
    end

    # Returns all instances, keyed by hostname, either from a serialized cache
    # or straight from AWS.
    #
    def instances
      File.open(@cache_file, File::RDWR|File::CREAT, 0600) do |f|
        # Be thread/process safe by grabbing a file mutex
        notify "locking cache file", @cache_file
        f.flock(File::LOCK_EX)

        # Is the cache new or too old?
        if f.stat.size == 0 or f.stat.mtime < (Time.now - @cache_life)
          notify "fetching and caching instances"
          f.write(load_instances.to_yaml)
          f.flush
          f.truncate(f.pos)
        else
          notify "cache is new enough", f.stat.mtime
        end
      end

      @instances ||= YAML.load(File.open(@cache_file))
    end

    def load_instances
      @instances ||= @ec2.describe_instances.reservationSet.item.inject({}) do |i,set|
        instance = set.instancesSet.item[0]
        instance["group"] = set.groupSet.item[0].groupId
        i[within_aws? ? instance.privateDnsName : instance.dnsName] = instance
        i
      end
    end

    def method_missing(method, *args)
      @ec2.send(method, *args)
    end

    private

    def default_cache_file
      # Include process uid to avoid permission issues when run by different users.
      File.join(Dir.tmpdir, "ae-instance-cache-#{Process.uid}.yml")
    end

    def notify(*args)
      changed
      notify_observers(*args)
    end

    # Determines whether we're executing from inside AWS.
    #
    def within_aws?
      @aws_addr_info ||= Socket.getaddrinfo("169.254.169.254", 80, Socket::AF_INET)
      @aws_addr_info.first[2] == "instance-data.ec2.internal"
    rescue SocketError
      false
    end
  end
end
