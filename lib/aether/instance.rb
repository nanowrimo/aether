module Aether
  module Instance
    autoload :Camp, 'aether/instance/camp'
    autoload :Default, 'aether/instance/default'
    autoload :Database, 'aether/instance/database'
    autoload :DatabaseSlave, 'aether/instance/database_slave'
    autoload :DevDatabase, 'aether/instance/dev_database'
    autoload :DevFilaments, 'aether/instance/dev_filaments'
    autoload :DevWeb, 'aether/instance/dev_web'
    autoload :Filaments, 'aether/instance/filaments'
    autoload :FilamentsWorker, 'aether/instance/filaments_worker'
    autoload :MockCamp, 'aether/instance/mock_camp'
    autoload :MockCampSupport, 'aether/instance/mock_camp_support'
    autoload :MockCampProxy, 'aether/instance/mock_camp_proxy'
    autoload :MockDatabase, 'aether/instance/mock_database'
    autoload :Store, 'aether/instance/store'
    autoload :StoreWorker, 'aether/instance/store_worker'
    autoload :Stressor, 'aether/instance/stressor'
    autoload :Util, 'aether/instance/util'
    autoload :Web, 'aether/instance/web'

    class UnlaunchedInstanceError < StandardError; end

    class RemoteExecutionError < StandardError
      attr_reader :exit_status

      def initialize(cmd, stderr = nil, code = nil)
        @exit_status = code
        super("failed to execute `#{cmd}': #{stderr}")
      end
    end

    class << self
      include UserLibrary

      # Returns all instances from the given or latest connection.
      #
      def all(connection = nil)
        connection ||= Connection.latest
        ins = connection.load_instances.map { |(host,info)| new(info.group, connection) { info } }
        ins.sort_by(&:launch_time).extend(InstanceCollection)
      end

      # Finds the running instance with the given id.
      #
      def find(id, connection = nil)
        all(connection).detect { |instance| instance.id == id }
      end

      # Instantiates an instance of the given type.
      #
      def new(type = nil, connection = nil, &blk)
        klass = type && classify(type)

        instance = if klass && self.const_defined?(klass) && (klass = self.const_get(klass))
          if klass.ancestors.include?(Default)
            klass.new(&blk)
          else
            Default.new(&blk)
          end
        else
          Default.new(&blk)
        end

        instance.connection = connection || Connection.latest

        instance
      end

      # Instantiates an instance of the given type and runs it.
      #
      def create(type, connection = nil)
        new(type).launch!
      end
    end
  end
end
