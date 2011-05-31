$:.unshift(File.dirname(__FILE__))

require 'rubygems'
require 'socket'

module Aether
  autoload :Connection, 'aether/connection'
  autoload :Notifier, 'aether/notifier'
  autoload :OptionParser, 'aether/option_parser'

  # Commands
  autoload :PuppetClassifier, 'aether/puppet_classifier'
end
