require 'aether/command'

require 'yaml'
require 'resolv'

module Aether

  # Classifies Puppet nodes based on the security group they're running in.
  #
  class PuppetClassifier < Command

    # Initializes a new puppet classifier.
    #
    def initialize(options = {})
      super("puppet-classfifier", "[options] HOST", options)
    end

    # Classifies the given host into a Puppet class and returns the YAML used
    # for configuration via +external_nodes+ in +puppet.conf+.
    #
    def classify(host)
      notify "classifying host", host

      address = Resolv.getaddress(host)

      instance = @connection.instances.values.find do |instance|
        instance.privateIpAddress == address || instance.ipAddress == address
      end

      notify(*(instance ? ["found instance", instance.instanceId] : ["no instance found"]))

      instance ? export(instance).to_yaml : ''
    end

    private

    def ec2_key(key)
      key.to_s.gsub(/([a-z\d])([A-Z])/, '\1_\2').downcase
    end

    # Build a corpus of data that the puppet manifests should have.
    #
    def export(instance)
      # Hyphens aren't allowed in class names, so replace them with underscores.
      classification = { 'classes' => [ instance.group.tr('-', '_') ] }

      parameters = {'aether' => {
        'name' => aether_name(instance),
        'domain' => 'aether.lettersandlight.org',
        'fqdn' => "#{aether_name(instance)}.aether.lettersandlight.org"
      }}

      # Serialize all instances and group by security group
      parameters[ec2_key('groups')] = @connection.instances.inject({}) do |hash, (k,i)|
        hash[i.group] ||= {}
        hash[i.group][aether_name(i)] = serialize(i) if i.instanceState.name == 'running'
        hash
      end

      parameters[ec2_key('instance')] = serialize(instance)

      classification['parameters'] = parameters

      classification
    end

    # Serializes the given instance as output suitable for puppet.
    #
    def serialize(instance)
      instance.inject({}) do |hash, (k, v)|
        if v.is_a?(String) || v.is_a?(Fixnum)
          hash[ec2_key(k)] = v
        elsif k == 'placement'
          hash[ec2_key('zone')] = v.availabilityZone
        end
        hash
      end
    end
  end
end
