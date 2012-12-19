module Aether
  module MetaDisk
    def self.scan(instance)
      Device.parse(instance, instance.exec!('mdadm --examine --scan'))
    end

    class Device
      PATTERN = /^ARRAY ([^ ]+) level=([^ ]+) (?:metadata=(\d+(?:\.\d+)) )?num-devices=(\d+) UUID=([^ ]+)(?: name=([^ ]+))?$/

      class << self
        def parse(instance, output)
          devices = []

          output.each_line do |line|
            if m = line.match(PATTERN)
              devices << new(instance, :path => m[1], :level => m[2], :metadata => m[3].to_f,
                                       :devices => m[4].to_i, :uuid => m[5].chomp, :name => m[6])
            end
          end

          devices
        end
      end

      attr_reader :path, :level, :metadata, :devices, :uuid, :name

      def initialize(instance, attributes = {})
        @instance = instance

        @path = attributes[:path]
        @level = attributes[:level]
        @metadata = attributes[:metadata]
        @devices = attributes[:devices]
        @uuid = attributes[:uuid]
        @name = attributes[:name]
      end

      def assemble!
        @instance.exec!("mdadm --assemble --uuid=#{uuid} #{path}")
      end

      def assembled?
        @instance.exec!("mdadm --query --detail --test #{path}").each_line
      rescue Instance::RemoteExecutionError => e
        e.exit_status != 4
      else
        true
      end

      def check(type)
        @instance.exec!("fsck.#{type} #{path}")
      end

      def disassemble!
        @instance.exec!("mdadm --stop #{path}")
      end
    end
  end
end
