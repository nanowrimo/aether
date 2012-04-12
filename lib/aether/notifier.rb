module Aether
  class Notifier
    def initialize(verbosity)
      @verbosity = verbosity
    end

    def update(message, *args)
      if message == :debug
        return if @verbosity < 2
        message = args.shift
      end

      STDERR.puts message.to_s + (args.length > 0 ? ': ' : '') + args.join('; ')
    end
  end
end
