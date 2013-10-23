module Aether
  module SnapshotRunCollection
    # Returns only the runs where all snapshots are completed.
    #
    def completed
      select { |snapshots| snapshots.all?(&:completed?) }
    end

    # Partitions the array of snapshot runs for pruning all but the given
    # number. Those to keep are selected evenly from across the collection and
    # returned in the first array. Those to destroy are returned as the second
    # array.
    #
    def keep(n)
      if n < 1
        [[], clone]
      elsif length <= n
        [clone, []]
      else
        interval = (length + (length / n) - 1).to_f / n
        partition.with_index do |_, i|
          remainder = i % interval
          (0 <= remainder && remainder < 1)
        end
      end
    end

    # Partitions the snapshot runs into the given number of segments where
    # each segment contains the given ratio of the total elements of the
    # current and previous segments.
    #
    # This method is generally used to separate snapshot runs into tiers
    # before pruning them.
    #
    # Examples:
    #   (1..15).partition_into(3) # => [[1, 2, 3, 4, 5, 6, 7, 8, 9, 10], [11, 12, 13], [14, 15]]
    #   (1..10).partition_into(2, 1 / 2.to_f) #=> [[1, 2, 3, 4, 5], [6, 7, 8, 9, 10]]
    #
    def partition_into(tiers, ratio = nil, total = nil)
      ratio ||= 1 / tiers.to_f
      recursively_partition(self, tiers) { |i,len| i < (len - (len * ratio).ceil) }.map do |runs|
        runs.extend(SnapshotRunCollection)
      end
    end

    # Flattens the runs into an array of snapshots.
    #
    def snapshots
      flatten(1)
    end

    # Returns snapshots that are scheduled for removal according to the
    # rentention options and algorithm.
    #
    def stale(options = {})
      options = Snapshot.retention_options.merge(options)

      tiers = options[:tiers].to_i

      # Make sure we have enough keep policies to cover the number of tiers
      keep = Array(options[:keep]).map(&:to_i)
      keep.fill(keep.last, keep.length...tiers)

      completed.partition_into(tiers).map.with_index { |tier,i| tier.keep(keep[i]).last }.flatten(1)
    end

    private

    def recursively_partition(values, segments, &blk)
      if segments < 2
        [values.clone]
      else
        parts = values.partition.with_index { |_,i| yield i, values.length }
        [parts.first] + recursively_partition(parts.last, segments - 1, &blk)
      end
    end
  end
end
