$:.unshift(File.dirname(__FILE__))

require 'rubygems'
require 'socket'

module Aether
  autoload :Config, 'aether/config'
  autoload :Connection, 'aether/connection'
  autoload :Dns, 'aether/dns'
  autoload :Ec2Model, 'aether/ec2_model'
  autoload :Instance, 'aether/instance'
  autoload :InstanceCollection, 'aether/instance_collection'
  autoload :Notifier, 'aether/notifier'
  autoload :OptionParser, 'aether/option_parser'
  autoload :Volume, 'aether/volume'
  autoload :VolumeCollection, 'aether/volume_collection'

  # Commands
  autoload :PuppetClassifier, 'aether/puppet_classifier'
  autoload :Launcher, 'aether/launcher'
  autoload :Shell, 'aether/shell'
end
