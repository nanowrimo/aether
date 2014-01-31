module Aether
  module Instance
    autoload :Default, 'aether/instance/default'

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
      def new(*arguments, &blk)
        options = (i = arguments.index { |arg| arg.is_a?(Hash) }) ? arguments.delete_at(i) : {}

        type, connection = *arguments

        begin
          klass = require_user(:instance, type)
        rescue NameError, LoadError
          klass = Default
        end

        klass.new(options, &blk).tap { |instance| instance.connection = connection || Connection.latest }
      end

      # Instantiates an instance of the given type and runs it.
      #
      def create(type, connection = nil)
        new(type).launch!
      end
    end
  end
end
