module Aether
  class Notifier
    def update(msg, *args)
      STDERR.puts msg + ': ' + args.join('; ')
    end
  end
end
