module Aether
  module SnapshotCollection
    def attach_to!(instance, options = {})
      each { |s| s.attach_to!(instance, options) }
      self
    end

    def of(type)
      where { run_type == type }
    end

    # Returns snapshots that match the given block (it returns true when
    # instance evaluated).
    #
    def where(&blk)
      select { |snapshot| snapshot.instance_exec(&blk) }.extend(SnapshotCollection)
    end

    # Returns snapshots in groups of runs.
    #
    def runs
      group_by(&:run_id).map { |id,snapshots| snapshots.extend(SnapshotCollection) }
    end
  end
end
