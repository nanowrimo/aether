module Aether
  class Snapshot
    include Ec2Model
    extend Observable

    RUN_INFO_FORMAT = /^([\w-]+):([^\s]+) \(([a-z0-9]+)\)/

    has_ec2_options(:volume_id, :description)

    class << self
      def all(connection = nil)
        connection ||= Connection.latest
        connection.describe_snapshots(:owner => "self").snapshotSet.item.map do |info|
          snapshot = Snapshot.new { info }
          snapshot.connection = connection
          snapshot
        end.sort_by(&:created_at).extend(SnapshotCollection)
      end

      # Finds the snapshot with the given id.
      #
      def find(id, connection = nil)
        connection ||= Connection.latest
        Snapshot.new { connection.describe_snapshots(:owner => "self", :snapshot_id => id).snapshotSet.item.first }
      end

      # Returns the configured snapshot retention options.
      #
      def retention_options(connection = nil)
        connection ||= Connection.latest
        {
          :tiers => connection.options[:snapshot_retention_tiers] || 3,
          :keep => connection.options[:snapshot_rentention_keep] || 10
        }
      end
    end

    def initialize(options = {})
      @options = options
      @info = block_given? ? yield : {}
    end

    def attach_to!(instance, options = {})
      create_volume_for({:instance_type => instance.type}.merge(options)).wait_for(&:available?).tap do |volume|
        volume.attach_to!(instance)
      end
    end

    def created?
      not @info.empty?
    end

    def created_at
      @info['startTime'] && Time.parse(@info['startTime'])
    end

    def description
      @info['description'] || ""
    end

    def destroy
      @connection.delete_snapshot(:snapshot_id => id)
    end

    def id
      snapshot_id
    end

    # Create a volume from the snapshot for the given instance type.
    #
    def create_volume_for(options = {})
      to_volume.create!.name!(volume.name_for(options))
    end

    def progress
      @info['progress']
    end

    def run_info
      if m = description.match(RUN_INFO_FORMAT)
        { :id => m[3], :type => m[1], :path => m[2] }
      else
        {}
      end
    end

    def run_id
      run_info[:id]
    end

    def run_type
      run_info[:type]
    end

    def status
      @info['status']
    end

    def to_s
      if created?
        "#{id}\t#{volume_id}\t#{run_type}\t#{created_at}\t#{status}"
      else
        "(new)\t#{volume_id}"
      end
    end

    def to_volume(options = {})
      options = {
        :snapshot_id => id,
        :size => volume.size,
        :availability_zone => volume.availability_zone
      }.merge(options)

      new_volume = Volume.new(options)
      new_volume.connection = @connection
      new_volume
    end

    def inspect
      if created?
        "#<snap:#{id}:#{volume_id}:#{run_type}:#{status}>"
      else
        "#<snap:(new):#{volume_id}:new>"
      end
    end

    def volume
      @volume ||= Volume.find(volume_id)
    end

    def volume_size
      @info['volumeSize']
    end
  end
end
