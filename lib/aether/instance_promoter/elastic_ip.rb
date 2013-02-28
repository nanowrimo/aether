require 'aether/instance_promoter/base'

module Aether
  module InstancePromoter
    class ElasticIp < Base

      # Demotes the instance by disassociating the Elastic IP from any 
      # instance. For this method to be successful in resolving the IP, a DNS
      # alias for the instance type (and the IP) must already exist.
      #
      def demote!
        elastic.instanceId && connection.disassociate_address(:public_ip => elastic.publicIp)
      end

      # Returns the instance currently associated with the Elastic IP.
      #
      def leader_instance
        elastic.instanceId && Instance.find(elastic.instanceId)
      end

      # Promotes the instance to leader by associating it with the Elastic IP.
      #
      def promote!
        leader = leader_instance

        unless instance == leader
          leader.demote!(instance) if leader
          public_ip = elastic.publicIp
          connection.associate_address(:public_ip => public_ip, :instance_id => instance.id)
        end

        instance.wait_for { |instance| instance.info.ipAddress == public_ip }
      end

      private

      def address
        leader_aliases.map { |cname| address_from_name(cname.values.first) }.compact.first
      end

      def elastic
        @elastic ||= connection.describe_addresses(:public_ip => address).addressesSet.item[0]
      end

      def leader_aliases
        connection.dns.aliases(instance.type)
      end

      # We could try to resolve by DNS, but external/internal consistencies
      # make it more difficult a method that simply deriving it from the DNS name.
      #
      def address_from_name(name)
        (m = name.match(/^ec2-(\d+)-(\d+)-(\d+)-(\d+)\./)) && m[1..4].join('.')
      end
    end
  end
end
