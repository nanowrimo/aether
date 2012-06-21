module Aether
  module VolumeCollection
    # Returns volumes that are attached to the given instance.
    #
    def attached_to(instance_id)
      where { attached_to?(instance_id) }
    end

    # Returns volumes that are available.
    #
    def available
      where { status == 'available' }
    end

    # Detaches all volumes in the collection.
    #
    def detach!(options = {})
      each { |volume| volume.detach!(options) }
    end

    # Returns volumes that belong to the given instance name.
    #
    def for(name)
      where { for?(name) }
    end

    # Returns the volumes that are meant to mount at the given directory.
    #
    def mounts_at(dir, position = nil)
      where { mount_point == dir && (position.nil? || raid_position == position) }
    end

    # Waits for all volumes in the collection.
    #
    def wait_for(&blk)
      each { |volume| volume.wait_for(&blk) }
    end

    # Returns volumes that match the given block (it returns true when
    # instance evaluated).
    #
    def where(&blk)
      select { |volume| volume.instance_exec(&blk) }.extend(VolumeCollection)
    end
  end
end
