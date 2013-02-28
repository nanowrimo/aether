module Aether
  module Environment
    class Base
      class << self
        attr_accessor :instances

        def has(number_of, instance_type)
          self.instances ||= {}
          self.instances[instance_type.to_s] ||= number_of
        end
      end

      attr_reader :type

      def initialize(type)
        @type = type
      end

      def start
        self.class.instances.inject({}) do |instances,(type,number_of)|
          instances.tap do |instances|
            instances[type] = number_of.times.collect do
              Instance.create(type).tap do |instance|
                instance.promote!
                3.times { instance.configure! }
              end
            end
          end
        end
      end
    end
  end
end
