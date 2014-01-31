require 'route53'

module Aether

  # Provides a CRUD interface to DNS records.
  #
  # Assumes use of Route53 at the moment.
  #
  class Dns
    attr_reader :zone

    def initialize(options)
      @options = options
      @r53 = Route53::Connection.new(options[:access_key], options[:secret_key])

      raise DnsError.new("no DNS zone is configured") unless options.has_key?(:dns_zone)

      self.zone = @options[:dns_zone] unless @options[:skip_dns]
    end

    # Attempts to find a zone with the given name for the current DNS
    # connection. A `DnsError` is raised if none is found.
    #
    def find_zone(name)
      zones.find { |zone| zone.named?(name) } or raise DnsError.new("zone #{name} does not exist")
    end

    def zone=(name)
      @zone = find_zone(name)
    end

    def zones
      @zones ||= @r53.get_zones.map { |z| Zone.new(@r53, z, @options) }
    end

    class Zone
      def initialize(connection, zone, options = {})
        @r53 = connection
        @zone = zone
        @options = options
      end

      # Creates and returns a new DNS record.
      #
      def create(name, type, ttl, values)
        name = qualify(name)
        record = DnsRecord.new(name, type, ttl, values, @zone)
        record.create("Created #{Time.now} by aether.")
        record
      end

      # Creates a new CNAME record using the given or default TTL.
      #
      def create_alias(alias_name, canonical_name, ttl = nil)
        create(alias_name, 'CNAME', ttl || @options[:dns_ttl], [canonical_name])
      end

      # Finds all CNAME records for the given name.
      #
      def aliases(alias_name)
        alias_name = qualify(alias_name)
        where { type == 'CNAME' && name == alias_name }
      end

      # Returns the name of the zone.
      #
      def name
        @zone.name
      end

      # Whether the given name matches the zone name, regardless of any
      # terminating root zone '.'. 
      #
      def named?(zone_name)
        (zone_name.end_with?('.') ? zone_name : "#{zone_name}.") == name
      end

      # Fully qualifies the given name, if it isn't already, using the DNS zone.
      #
      def qualify(host)
        host.end_with?('.') ? host : "#{host}.#{name}"
      end

      # Returns all records in the DNS zone.
      #
      def records
        @zone.get_records.map { |record| record.extend(DnsRecordAdditions) }
      end

      # Returns the root A record.
      #
      def root
        records.find { |record| record.name == name && record.type == 'A' }
      end

      # Returns all records from the current DNS zone that match the given
      # block.
      #
      def where(&blk)
        records.select { |record| record.instance_exec(&blk) }
      end
    end
  end

  class DnsError < StandardError; end

  module DnsRecordAdditions
    def inspect
      "#<dns:#{name}:#{type}:#{ttl}:#{values.join(',')}>"
    end

    def named?(record_name)
      (record_name.end_with?('.') ? record_name : "#{record_name}.") == name
    end

    def update(params = {})
      super(params[:name], params[:type], params[:ttl], params[:values])
    end
  end

  class DnsRecord < Route53::DNSRecord
    include DnsRecordAdditions
  end
end
