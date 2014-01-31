require 'aether/instance_promoter/base'

module Aether
  module InstancePromoter
    class DnsAlias < Base

      # Demotes the instance by removing the DNS alias that matches the
      # instance type.
      #
      def demote!
        leader_aliases.each(&:delete)
      end

      # Returns the instance having a DNS alias that matches the instance
      # type.
      #
      def leader_instance
        if cname = leader_aliases.first
          Instance.all(connection).detect { |instance| cname.values.include?(instance.dnsName) }
        end
      end

      # Promotes the instance to leader by creating a DNS alias.
      #
      def promote!
        leader = leader_instance

        unless instance == leader
          leader.demote!(instance) if leader
          aliases = leader_aliases.collect do |cname|
            cname.update(:values => [ instance.dnsName ], :ttl => 60)
          end
          instance.create_dns_alias(instance.type, 60) if aliases.empty?
        end
      end

      private

      def leader_aliases
        dns.zone.aliases(instance.type)
      end

      def dns
        connection.dns
      end

    end
  end
end
