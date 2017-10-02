require 'AWS'
require 'observer'
require 'tempfile'
require 'yaml'

module Aether
  IMAGE_PATTERN = %r{^[^/]+/oll-(.+?)(?:-(?:32|64)bit)?-r([0-9]+)\.manifest\.xml$}

  class Connection
    include Observable

    class << self
      attr_accessor :latest

      def new(*args)
        self.latest = super(*args)
      end
    end

    attr_accessor :access_key, :secret_key
    attr_reader :options, :dns

    def initialize(options = {})
      self.access_key = options[:access_key]
      self.secret_key = options[:secret_key]

      @ec2 = AWS::EC2::Base.new(:access_key_id => access_key, :secret_access_key => secret_key)
      @dns = Dns.new(options)

      @cache_file = options[:cache_file] || default_cache_file
      @cache_life = options[:cache_life] || (4 * 60)

      @options = options
    end

    # Returns all AMI information.
    #
    def images
      @ec2.describe_images(:owner_id => "self").imagesSet.item.inject([]) do |images,i|
        i["name"], i["revision"] = *i.imageLocation.match(IMAGE_PATTERN).captures
        i["revision"] = i["revision"].to_i
        images << i
      end
    end

    # Returns all instances, keyed by hostname, either from a serialized cache
    # or straight from AWS.
    #
    def instances(force_expire = false)
      File.open(@cache_file, File::RDWR|File::CREAT, 0600) do |f|
        # Be thread/process safe by grabbing a file mutex
        notify :debug, "locking cache file", @cache_file
        f.flock(File::LOCK_EX)

        # Is the cache new or too old? (or are we being forced to expire it?)
        if f.stat.size == 0 or f.stat.mtime < (Time.now - @cache_life) or force_expire
          notify "fetching and caching instances"
          f.write(load_instances.to_yaml)
          f.flush
          f.truncate(f.pos)
        else
          notify :debug, "cache is new enough", f.stat.mtime
        end
      end

      @instances ||= YAML.load(File.open(@cache_file))
    end

    def load_instances(*args)
      # keep track of instance positions in each group
      positions = {}

      @ec2.describe_instances(*args).reservationSet.item.inject({}) do |i,set|
        instance = set.instancesSet.item[0]
	begin
	        instance["group"] = set.groupSet.item[0].groupId
        rescue
		instance["group"] = 0
	end
        positions[instance["group"]] ||= 0
        instance["position"] = positions[instance["group"]]
        positions[instance["group"]] += 1

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
      return @options[:within_aws] if @options.include?(:within_aws)

      @aws_addr_info ||= Socket.getaddrinfo("169.254.169.254", 80, Socket::AF_INET)
      @aws_addr_info.first[2] == "instance-data.ec2.internal"
    rescue SocketError
      false
    end
  end
end
