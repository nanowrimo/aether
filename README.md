# Aether

Aether project contains tools for management of AWS infrastructure, most
notably the Aether Ruby shell (`ae-shell`). It's intended mainly for querying,
provisioning, and shutdown of "machine" resources, not OS- and
application-level configuration which is better left to tools like
[Puppet](http://puppetlabs.com/). (It does, however, include helpers for
invoking Puppet configuration on demand!)

This gem was initially developed by [National Novel Writing
Month](http://nanowrimo.org) for use in managing its AWS-backed website
infrastructure its event website. It has since been released under the GPL.

## Installation

For now, there's a Makefile, but a gem is in the works.

    git clone git@github.com:marxarelli/aether.git
    cd aether
    sudo make install

The Makefile will install everything under `/usr/local/lib/aether` with links
to scripts in `/usr/local/bin`.

## Configuration

By default, Aether looks for its configuration at `~/.aether/config.yml`.

    default:
      access_key: ~/.ec2/access.key
      secret_key: ~/.ec2/secret.key
      ssh_keys: [~/.ec2/dduvall.pem]
      key_name: dduvall

As you can see, default options are given under `default:`. You can also
limit options to only specific commands.

    default:
      access_key: ~/.ec2/access.key
      secret_key: ~/.ec2/secret.key
      ssh_keys: [~/.ec2/admin.pem]
      key_name: dduvall
    shell:
      access_key: ~/.ec2/my-access.key
      secret_key: ~/.ec2/my-secret.key

Each config entry corresponds to a command-line-parameter equivalent, so you
can always override these when executing a command.

    ~ $ ae-shell --access-key tmp-access.key --secret-key tmp-secret.key

And see which options are available by viewing the command usage.

    ~ $ ae-shell --help

    Usage: ae-shell [options]
            --config FILE                A file containing default command options.
        -a, --access-key FILE            A file containing the AWS access key.
        -s, --secret-key FILE            A file containing the AWS secret key.
        -z, --dns-zone ZONE              The DNS zone in which instances live.
            --dns-ttl TTL                The default DNS TTL to use when creating records.
        -c, --cache-file FILE            A file for caching instance data.
        -l, --cache-life SECONDS         The cache life in seconds.
        -u, --ssh-user USER              User to use when starting SSH sessions.
        -i, --ssh-key PATH               SSH identity file to try when connecting.
        -v, --verbose                    Describe what's going on.
            --within-aws                 Whether executing within the internal AWS network.
        -k, --key-name NAME              The EC2 key-pair name to use.
            --skip-dns                   Don't interact with DNS.
        -h, --help                       Show this message.

## Aether Shell

### Basic Usage

    ~ $ ae-shell
    >> _

Aether shell uses [Ripl](https://github.com/cldwalker/ripl) so just about any
Ruby code is valid.

    >> self.class
    => Aether::Shell::Sandbox
    >> self.class.instance_methods(false)
    => [:instance, :instances, :dns, :launch, :new, :open, :open_url, :snapshots, :volume, :volumes, :method_missing]

The sandbox provides helper methods to access resource classes like `Instance`
and `Volume`, or commonly used methods like `Instance.all`.

    >> Instance.all.length
    => 63
    >> instances.length
    => 63

In fact, `Instance.all` is so commonly used to query for instance resources
that any instance method of `InstanceCollection` called directly in the shell
is inferred to be a call to `Instance.all`, letting you simply say:

    >> running.in("web")
    => [#<ins:web:i-7de33615:running>, #<ins:web:i-ae85ebce:running>, ...]

The default output format is pretty cryptic, a reflection of the author. Any
time you'd like something a little more friendly, try using `to_s` or simply
`puts`.

    >> puts running.in("web")
    web-7de33615	running	2009-09-21 22:00:09 UTC
    web-ae85ebce	running	2011-09-28 02:36:10 UTC
    web-41150839	running	2013-10-30 19:32:38 UTC
    web-79076803	running	2013-10-30 19:33:39 UTC
    web-6f076815	running	2013-10-30 19:34:27 UTC
    web-6e0a2c08	running	2013-10-30 19:35:16 UTC
    web-471a073f	running	2013-10-30 19:37:02 UTC
    web-0b1a0773	running	2013-10-30 19:37:58 UTC
    web-a7b9e7c2	running	2013-10-30 19:38:49 UTC
    web-2db8e648	running	2013-10-30 19:39:44 UTC

And, again, because this is just Ruby (and because this documentation needs a
lot of work), investigate the objects to see what you can do! (Take a look at
`Aether::Shell::Sandbox` for the implementation of shell helpers.)

    >> throw_money_at_it = 20.times.collect { new }
    => [#<ins:default:(new)>, #<ins:default:(new)>, ...]
    >> throw_money_at_it.each(&:launch!)

(NOTE: Don't actually throw money at your problems.)

### Instance Profiles

Profiles for instance resources can be defined in the User Library under
`~/.aether/lib/instance`. An instance profile is simply a Ruby class that
extends `Aether::Instance::Default`.

>> Wait, the shell is just a Ruby shell? Profiles are just Ruby classes? In
>> the wrong hands...

Yes, well, in the right hands—and with the right IAM restrictions in
place—these are powerful and safe constructs for managing your AWS
infrastructure!

#### Examples

You could, for example, write a base profile for all of your Debian systems
that bootstraps the base Debian AMI to a point where Puppet can take over.

    class DebianWheezy < Aether::Instance::Default
      include InstanceHelpers::Debian

      self.type = "default"
      self.default_options = { :image_id => "ami-50d9a439" }

      after(:run) do
        wait_for { running? && ssh?(:user => 'admin') }

        authorize_root_login
        upgrade_packages
        install_packages(:resolvconf, :curl)
        configure_domain

        install_packages(:puppet) if @options[:configure_by] == :puppet
      end
    end

To illustrate the extent of Aether's power, consider the following profile of
a scalable database instance we used in the early days of AWS, before RDS
existed.

    class Database < Aether::Instance::Default
      include InstanceHelpers::MetaDisk

      self.type = "database"
      self.default_options = {
        :elastic_ip => "",
        :instance_type => "m2.4xlarge",
        :image_name => "database-master",
        :availability_zone => "us-east-1b",
        :promote_by => :elastic_ip,
        :configure_by => nil
      }

      before(:demotion) do
        exec!("invoke-rc.d mysql stop", "umount /var/lib/mysql", "umount /mnt/mysqld")
        meta_disk_devices.each(&:disassemble!)
        attached_volumes.each(&:detach!)
      end

      after(:promotion) do
        volumes.wait_for { |volume| volume.available? }
        attach_volumes!
        volumes.wait_for { |volume| volume.attached? && file_exists?(volume.device) }

        meta_disk_devices.each(&:assemble!)
        meta_disk_devices.each { |md| md.check(:xfs) }

        exec!("ln -nfs #{mysql_sized_config_path} /etc/mysql/my-sized.cnf")
        exec!("mount /var/lib/mysql", "mount /mnt/mysqld", "invoke-rc.d mysql start")
      end

      def mysql_sized_config_path
        "/etc/mysql/my-#{info.instanceType.sub(/^[^\.]+\./, '')}.cnf"
      end
    end

#### Using Profiles in the Shell

By default, Aether tries to match your instance profiles with running
instances using the name of the instance's first security group—there are
plans to make this profile mapping more flexible.

    >> webs = running.in("web")
    => [#<ins:web:i-7de33615:running>, #<ins:web:i-ae85ebce:running>, ...]
    >> webs.first.class
    => Web

Similarly, when you instantiate a new instance resource, the given name is
mapped to an existing profile.

    >> more_webs = 3.times.collect { new("web") }
    => [#<ins:web:(new)>, #<ins:web:(new)>, #<ins:web:(new)>]
    >> more_webs.first.class
    => Web

## Roadmap

 - Better documentation and examples
 - Port to `aws-sdk`
 - Safe parallel execution in the shell
 - Test coverage!

## Contributions

Aether was developed in a pretty isolated environment for the use cases of
National Novel Writing Month. For an open-source project to thrive, it needs
contributors. So please, if you find this gem at all useful, please
contribute!

 - Fork the project and create a topic branch
 - Write tests for your new feature or a test that reproduces a bug
 - Implement your feature or make a bug fix
 - Commit, push and make a pull request

## License

Aether is licensed under the terms of the GPL v3.

## Copyright

Copyright (c) 2013 Daniel Duvall
