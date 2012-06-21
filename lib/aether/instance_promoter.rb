module Aether
  module InstancePromoter

    autoload :DnsAlias, 'aether/instance_promoter/dns_alias'
    autoload :Null, 'aether/instance_promoter/null'

    class << self
      # Instantiates an instance promoter of the given type.
      #
      def new(type, instance)
        klass = self.const_get(classify(type))
        klass.ancestors.include?(Base) ? klass.new(instance) : Base.new(instance)
      end

      private

      def classify(name)
        name.to_s.gsub(/\/(.?)/) { "::#{$1.upcase}" }.gsub(/(?:^|_|-)(.)/) { $1.upcase }.to_sym
      end
    end

  end
end
