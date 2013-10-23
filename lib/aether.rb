$:.unshift(File.dirname(__FILE__))

require 'rubygems'
require 'socket'

module Aether
  autoload :Config, 'aether/config'
  autoload :Connection, 'aether/connection'
  autoload :Dns, 'aether/dns'
  autoload :Ec2Model, 'aether/ec2_model'
  autoload :Environment, 'aether/environment'
  autoload :Instance, 'aether/instance'
  autoload :InstanceCollection, 'aether/instance_collection'
  autoload :InstanceConfigurator, 'aether/instance_configurator'
  autoload :InstanceHelpers, 'aether/instance_helpers'
  autoload :InstancePromoter, 'aether/instance_promoter'
  autoload :MetaDisk, 'aether/meta_disk'
  autoload :Notifier, 'aether/notifier'
  autoload :OptionParser, 'aether/option_parser'
  autoload :Snapshot, 'aether/snapshot'
  autoload :SnapshotCollection, 'aether/snapshot_collection'
  autoload :SnapshotRunCollection, 'aether/snapshot_run_collection'
  autoload :Volume, 'aether/volume'
  autoload :VolumeCollection, 'aether/volume_collection'
  autoload :UserLibrary, 'aether/user_library'

  # Commands
  autoload :PuppetClassifier, 'aether/puppet_classifier'
  autoload :Launcher, 'aether/launcher'
  autoload :Shell, 'aether/shell'

  class << self
    attr_accessor :user_load_path
  end

  self.user_load_path = File.expand_path("~/.aether/lib")
end
