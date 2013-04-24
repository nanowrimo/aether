module Aether
  module Instance
    class Archive < Default
      self.type = "archive"
      self.default_options = {
        :instance_type => "c1.medium",
        :promote_by => :dns_alias
      }

      before(:demotion) do
        attached_volumes.each(&:detach!)
      end

      after(:promotion) do
        volumes.wait_for { |volume| volume.available? }
        attach_volumes!
        volumes.wait_for { |volume| volume.attached? && file_exists?(volume.device) }
      end
    end
  end
end
