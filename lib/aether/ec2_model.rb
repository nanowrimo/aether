module Aether
  module Ec2Model
    def method_missing(method, *args)
      key = method.to_s.gsub(/_(.)/) { $1.upcase }

      raise NoMethodError, "undefined method #{method}" unless @info && @info.has_key?(key)

      @info[key]
    end
  end
end
