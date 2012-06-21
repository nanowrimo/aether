module Aether
  module Ec2Model
    include Observable

    def self.included(base)
      base.extend ClassMethods
    end

    attr_accessor :connection

    def method_missing(method, *args)
      key = method.to_s.gsub(/_(.)/) { $1.upcase }

      raise NoMethodError, "undefined method #{method}" unless @info && @info.has_key?(key)

      @info[key]
    end

    protected

    def around_callback(event, *arguments, &blk)
      invoke_callback(:before, event)
      result = yield *arguments
      invoke_callback(:after, event)
      result
    end

    def invoke_callback(context, event)
      self.class.callbacks[event][context].each { |callback| instance_exec(&callback) }
    rescue NoMethodError
      nil
    end

    module ClassMethods

      attr_accessor :callbacks

      def after(event, &blk)
        define_callback(:after, event, &blk)
      end

      def before(event, &blk)
        define_callback(:before, event, &blk)
      end

      def has_ec2_option(name)
        ec2_name = name.to_s.gsub(/_([a-z0-9])/) { $1.upcase }
        global_name = self.name.sub(/.*::/, '').sub(/^([A-Z])/) { $1.downcase }
        global_name = global_name.gsub(/([A-Z])/) { "_#{$1.downcase}" } + "_#{name}"

        class_eval <<-end_class_eval
          def #{name}
            @info['#{ec2_name}'] || @options[:#{name}] || connection.options[:#{global_name}]
          end
        end_class_eval
      end

      def has_ec2_options(*names)
        names.each { |name| has_ec2_option(name) }
      end

      private

      def define_callback(context, event, &blk)
        self.callbacks ||= {}
        self.callbacks[event] ||= {}
        self.callbacks[event][context] ||= []

        self.callbacks[event][context] << blk
      end
    end
  end
end
