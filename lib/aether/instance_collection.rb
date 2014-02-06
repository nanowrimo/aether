module Aether
  module InstanceCollection
    # Executes the given command on all instances in the collection and
    # returns a hash keyed by the instance host name with the output for each.
    #
    def exec!(cmd, &blk)
      inject({}) { |outputs,i| i.ssh { |sh| outputs[i.name] = sh.exec!(cmd, &blk) }; outputs }
    end

    # Returns instances that are currently running.
    #
    def running
      in_state('running')
    end

    # Returns instances from the given group.
    #
    def in(*groups)
      where { groups.include?(group) }
    end

    # Returns instances that are in the given state.
    #
    def in_state(given_state)
      where { state == given_state }
    end

    # Returns instances that launched on the given date. Launch times are
    # adjusted to the local time zone before being converted to dates and
    # compared.
    #
    def launched(date)
      date = Date.new(date.year, date.month, date.day) if date.is_a?(Time)

      where do
        offset_time = launch_time + Time.now.utc_offset
        Date.new(offset_time.year, offset_time.month, offset_time.day) == date
      end
    end

    # Returns instances that launched after the given time.
    #
    def launched_since(time)
      where { launch_time > time }
    end

    # Returns instances that are currently pending.
    #
    def pending
      in_state('pending')
    end

    # Returns instances that are shutting down.
    #
    def shutting_down
      in_state('shutting-down')
    end

    # Returns instances that have stopped.
    #
    def stopped
      in_state('stopped')
    end

    # Returns instances that are stopping.
    #
    def stopping
      in_state('stopping')
    end

    # Terminates all instances in the collection.
    #
    def terminate!
      each { |instance| instance.terminate! }
    end

    # Returns instances that have terminated.
    #
    def terminated
      in_state('terminated')
    end

    # Returns instances that match the given block (it returns true when
    # instance evaluated).
    #
    def where(&blk)
      select { |instance| instance.instance_exec(&blk) }.extend(InstanceCollection)
    end

    # A current usage summary by the given `group_by` block.
    #
    def usage_by(&blk)
      group_by(&blk).sort_by { |key| key }.each.with_object({}) do |(key,group),report|
        report[key] = group.group_by { |i| i.info.instanceType }.each.with_object({}) do |(key,group),report|
          report[key] = group.length
        end
      end
    end

    # A current usage summary by availability zone which may be useful in
    # optimizing things like instance reservations.
    #
    def usage_by_availability_zone
      usage_by { |instance| instance.info.placement.availabilityZone }
    end

    # A current usage summary by type (role).
    #
    def usage_by_type
      usage_by { |instance| instance.type }
    end
  end
end
