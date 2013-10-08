module Aether
  module Instance
    class DebianWheezy < Default
      include InstanceHelpers::Debian

      self.type = "default"
      self.default_options = {:image_id => "ami-50d9a439"}

      after(:run) do
        wait_for { running? && ssh?(:user => 'admin') }

        authorize_root_login
        upgrade_packages
        install_packages(:resolvconf, :curl)
        configure_domain

        install_packages(:puppet) if @options[:configure_by] == :puppet
      end
    end
  end
end
