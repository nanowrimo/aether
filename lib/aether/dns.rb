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

      options[:dns_zone] += '.' unless options[:dns_zone].end_with?('.')

      # resolve the configured zone
      unless options[:skip_dns]
        @zone = @r53.get_zones.detect { |zone| zone.name == options[:dns_zone] }
        raise DnsError.new("zone #{options[:dns_zone]} does not exist") unless @zone
      end
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

    # Fully qualifies the given name, if it isn't already, using the DNS zone.
    #
    def qualify(name)
      name += ".#{@zone.name}" unless name.end_with?('.')
    end

    # Returns all records in the DNS zone.
    #
    def records
      @zone.get_records.map { |record| record.extend(DnsRecordAdditions) }
    end

    # Returns all records from the current DNS zone that match the given
    # block.
    #
    def where(&blk)
      records.select { |record| record.instance_exec(&blk) }
    end
  end

  class DnsError < StandardError; end

  module DnsRecordAdditions
    def inspect
      "#<dns:#{name}:#{type}:#{ttl}:#{values.join(',')}>"
    end

    def update(params = {})
      update(params[:name], params[:type], params[:ttl], params[:values])
    end
  end

  class DnsRecord < Route53::DNSRecord
    include DnsRecordAdditions
  end
end
