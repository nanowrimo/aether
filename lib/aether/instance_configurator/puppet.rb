require 'aether/instance_configurator/base'

module Aether
  module InstanceConfigurator
    class Puppet < Base

      def configure!(*flags)
        flags |= [:onetime, :'no-daemonize', :'no-usecacheonfailure', :'ignorecache']
        instance.exec!("puppet agent #{flags.map { |f| "--#{f}" }.join(' ')}")
        nil
      end

    end
  end
end
