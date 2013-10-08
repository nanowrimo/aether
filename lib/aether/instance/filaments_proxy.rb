module Aether
  module Instance
    class FilamentsProxy < DebianWheezy
      self.type = "filaments-proxy"
      self.default_options = {
        :instance_type => "c1.medium", :promote_by => :dns_alias,
        :block_device_mapping => [ { :device_name => '/dev/sdb', :virtual_name => 'ephemeral0' } ]
      }
    end
  end
end
