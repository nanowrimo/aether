module Aether
  module InstanceHelpers
    module Debian
      # Debian publishes their AMIs with root login disabled and an "admin"
      # user with full sudo permission. This helper will reconfigure sshd to
      # allow login and copy all of admin's authorized ssh keys to root.
      #
      def authorize_root_login
        notify "authorizing root login"

        root_ssh_dir = "/root/.ssh"
        root_ssh_keys = "#{root_ssh_dir}/authorized_keys"

        exec!(<<-end_exec, :ssh => { :user => 'admin' })
          if sudo [ ! -f #{root_ssh_keys} ] || sudo grep -q 'Please login as the user' #{root_ssh_keys}; then
            sudo mkdir -p #{root_ssh_dir}
            sudo cp .ssh/authorized_keys #{root_ssh_keys}
            sudo chown root:root -R #{root_ssh_dir}
            sudo chmod 700 #{root_ssh_dir}
            sudo chmod 600 #{root_ssh_keys}
            sudo sed -i.aether.bak 's/^PermitRootLogin no$/PermitRootLogin yes/' /etc/ssh/sshd_config
            sudo invoke-rc.d ssh reload
          fi
        end_exec
      end

      def apt_get(command, *arguments)
        exec!("DEBIAN_FRONTEND=noninteractive apt-get -y #{command} #{arguments.join(" ")} > /dev/null")
      end

      def install_packages(*packages)
        notify "installing #{packages.join(" ")}"

        apt_get(:install, *packages)
      end

      def upgrade_packages
        notify "upgrading packages"

        apt_get(:update)
        apt_get(:upgrade)
      end

      def configure_domain
        domain = @connection.dns.zone.name.gsub(/\.$/, '')

        notify "setting domain to #{domain}"

        exec!(<<-end_exec)
          echo 'search #{domain}' >> /etc/resolvconf/resolv.conf.d/base
          resolvconf -u
          sed -i.aether.bak 's/^SET_DNS=/#SET_DNS/' /etc/default/dhcpcd
          /sbin/dhcpcd-bin -n eth0
        end_exec
      end
    end
  end
end
