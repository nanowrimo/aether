module Aether
  module Instance
    class Archive < Default
      self.type = "archive"
      self.default_options = {
        :instance_type => "c1.medium",
        :availability_zone => "us-east-1b",
        :promote_by => :dns_alias
      }

      before(:demotion) do
        exec!("invoke-rc.d varnish stop",
              "invoke-rc.d nginx stop",
              "grep '/dev/loop' /proc/mounts | while read x dir x; do umount $dir; done",
              "umount /var/www-archive || true")

        attached_volumes.each(&:detach!)
      end

      after(:promotion) do
        volumes.wait_for { |volume| volume.available? }
        attach_volumes!
        volumes.wait_for { |volume| volume.attached? && file_exists?(volume.device) }
        exec!("mkdir -p /var/www/archive /var/www-archive",
              "mount /dev/xvdh /var/www-archive",
              "/var/www-archive/mount_all.sh")
      end
    end
  end
end
