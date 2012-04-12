module Aether
  module Instance
    ARCHITECTURES = {
      "m1.small" => "i386",
      "m1.medium" => "x86_64",
      "m1.large" => "x86_64",
      "m1.xlarge" => "x86_64",
      "m2.xlarge" => "x86_64",
      "m2.2xlarge" => "x86_64",
      "m2.4xlarge" => "x86_64",
      "c1.medium" => "i386",
      "c1.xlarge" => "x86_64",
    }

    autoload :Default, 'aether/instance/default'
    autoload :Web, 'aether/instance/web'
    autoload :Store, 'aether/instance/store'
    autoload :Filaments, 'aether/instance/filaments'
    autoload :DevFilaments, 'aether/instance/dev_filaments'

    class << self

      # Returns all instances from the given or latest connection.
      #
      def all(connection = nil)
        connection ||= Connection.latest
        ins = connection.instances(true).map { |(host,info)| new(info.group, connection) { info } }
        ins.sort_by(&:launch_time).extend(InstanceCollection)
      end

      # Finds the running instance with the given id.
      #
      def find(id, connection = nil)
        all(connection).detect { |instance| instance.id == id }
      end

      # Instantiates an instance of the given type.
      #
      def new(type, connection = nil, &blk)
        klass = classify(type)

        instance = if self.const_defined?(klass) && (klass = self.const_get(klass))
          if klass.ancestors.include?(Default)
            klass.new(&blk)
          else
            Default.new(type, &blk)
          end
        else
          Default.new(type, &blk)
        end

        instance.connection = connection || Connection.latest

        instance
      end

      # Instantiates an instance of the given type and runs it.
      #
      def create(type, connection = nil)
        new(type).launch!
      end

      private

      def classify(name)
        name.to_s.gsub(/\/(.?)/) { "::#{$1.upcase}" }.gsub(/(?:^|_|-)(.)/) { $1.upcase }.to_sym
      end
    end
  end
end
