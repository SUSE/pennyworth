# Copyright (c) 2013-2015 SUSE LLC
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of version 3 of the GNU General Public License as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.   See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, contact SUSE LLC.
#
# To contact SUSE about this file by physical or electronic mail,
# you may find current contact information at www.suse.com

class Cli
  extend GLI::App

  program_desc 'A tool for controlling networks of machines for integration testing'
  program_long_desc <<-LONGDESC
    Pennyworth is a tool for controlling a network of machines for
    integration testing. It helps to control virtual and real machines to
    provide a well-defined test environment for automated tests.

    Use the global `--definitions-dir` option to specify the path to the
    directory containing Kiwi and Vagrant definitions. The directory needs to
    contain `kiwi/` and `vagrant/` subdirectories. Default is `~/.pennyworth`.

    Pennyworth writes a log file to `/tmp/pennyworth.log`.

    Use the `help` command to get documentation about the individual commands.
    Find more documentation at https://github.com/SUSE/pennyworth.
  LONGDESC

  preserve_argv(true)
  @version = Pennyworth::VERSION
  switch :version, :negatable => false, :desc => "Show version"
  switch [:help, :h], :negatable => false, :desc => "Show help"
  switch :verbose, :negatable => false, :desc => "Verbose"
  switch [:silent], :negatable => false, :desc => "Silent mode"
  flag ["definitions-dir", :d],
    :desc => "Path to the directory containing machine definitions",
    :arg_name => "DEFINITIONS_DIR"

  pre do |global_options,command,options,args|
    @@settings.verbose = !!global_options[:verbose]
    @@settings.silent = !!global_options[:silent]
    @@settings.definitions_dir = File.expand_path(
      global_options["definitions-dir"]
    ) if global_options["definitions-dir"]
    true
  end

  on_error do |e|
    case e
    when GLI::UnknownCommandArgument, GLI::UnknownGlobalArgument,
        GLI::UnknownCommand, GLI::BadCommandLine
      STDERR.puts e.to_s + "\n\n"
      command = ARGV & @commands.keys.map(&:to_s)
      run(command << "--help")
      exit 1
    when SystemExit
      raise
    when SignalException
      exit 1
    else
      STDERR.puts "Pennyworth experienced an unexpected error. Please file a " \
        "bug report at https://github.com/SUSE/pennyworth/issues/new.\n"
      if e.is_a?(Cheetah::ExecutionFailed)
        result = ""
        result << "#{e.message}\n"
        result << "\n"

        if e.stderr && !e.stderr.empty?
          result << "Error output:\n"
          result << "#{e.stderr}\n"
        end

        if e.stdout && !e.stdout.empty?
          result << "Standard output:\n"
          result << "#{e.stdout}\n\n"
        end

        if e.backtrace && !e.backtrace.empty?
          result << "Backtrace:\n"
          result << "#{e.backtrace.join("\n")}\n\n"
        end
        STDERR.puts result
        exit 1
      else
        raise
      end
    end
    true
  end

  def self.settings
    @@settings
  end

  def self.settings= s
    @@settings = s
  end

  desc "Prepare system for running Pennyworth"
  long_desc <<-LONGDESC
    Prepare the system to be able to run virtual machines via Pennyworth. This
    encapsulates package installation as well as set up of required tools such
    as Vagrant and libvirt.

    See https://github.com/SUSE/pennyworth#installation for more information.
  LONGDESC
  command :setup do |c|
    c.action do |global_options,options,args|
      SetupCommand.new.execute
    end
  end

  desc "Show status of virtual machine"
  long_desc <<-LONGDESC
    Show status of specified virtual machine. Use `list` to get a list of all
    available machines.
  LONGDESC
  arg_name "VM_NAME"
  command :status do |c|
    c.action do |global_options,options,args|
      vm_name = args.shift
      VagrantCommand.setup_environment(@@settings.vagrant_dir)
      StatusCommand.new.execute(vm_name)
    end
  end

  desc "Build base images"
  long_desc <<-LONGDESC
    Build base images used by Vagrant. If no specific name is given all base
    images are built. The images have to be imported with `import-base` to be
    available to be run.
  LONGDESC
  arg_name "IMAGE_NAME", :optional
  command "build-base" do |c|
    c.flag [:kiwi_tmp_dir, :k], :type => String, :required => false,
      :desc => "Temporary KIWI directory for building the Vagrant box.",
      :arg_name => "KIWI-TMP-Dir"
    c.action do |global_options,options,args|
      image_name = args.shift
      tmp_dir = options[:kiwi_tmp_dir] || "/tmp/pennyworth-kiwi-builds"
      BuildBaseCommand.new(Cli.settings.kiwi_dir).execute(tmp_dir, image_name)
    end
  end

  desc "Import base images"
  long_desc <<-LONGDESC
    Import base images used by Vagrant. If no specific name is given all base
    images are imported. Base images have to be built with `build-base` or
    imported from a remote location specified with the `--url` option.
  LONGDESC
  arg_name "IMAGE_NAME", :optional
  command "import-base" do |c|
    c.flag [:url, :u], :type => String, :required => false,
      :desc => "URL of the remote server where the images will be imported from", :arg_name => "URL"
    c.action do |global_options,options,args|
      image_name = args.shift
      VagrantCommand.setup_environment(@@settings.vagrant_dir)
      if options[:url]
        kiwi_dir = File.expand_path("~/.pennyworth/kiwi")
        remote_url = options[:url]
        opts = {
          local: false,
        }
      else
        if !Cli.settings.definitions_dir
          STDERR.puts "You need to specify a definitions directory when not using --url."
          exit 1
        end
        kiwi_dir = Cli.settings.kiwi_dir
        opts = {
          local: true
        }
      end
      ImportBaseCommand.new(kiwi_dir, remote_url).execute(image_name, opts)
    end
  end

  desc "Start virtual machine"
  long_desc <<-LONGDESC
    Start specified virtual machine
  LONGDESC
  arg_name "VM_NAME"
  command :up do |c|
    c.switch [:destroy], :default_value => false, :required => false, :negatable => false,
      :desc => "Destroy vagrant instance(s) before starting them."
    c.action do |global_options,options,args|
      vm_name = args.shift
      VagrantCommand.setup_environment(@@settings.vagrant_dir)
      UpCommand.new.execute(vm_name, options)
    end
  end

  desc "Stop virtual machine"
  long_desc <<-LONGDESC
    Stop specified virtual machine
  LONGDESC
  arg_name "VM_NAME"
  command :down do |c|
    c.action do |global_options,options,args|
      vm_name = args.shift
      VagrantCommand.setup_environment(@@settings.vagrant_dir)
      DownCommand.new.execute(vm_name)
    end
  end

  desc "Copy puplic SSH keys to target system"
  long_desc <<-LONGDESC
    Copy the public SSH keys to the host named IP-ADDRESS for easy root access
  LONGDESC
  arg_name "IP-ADDRESS"
  command :copy_ssh_keys do |c|
    c.flag [:password, :p], :type => String, :required => false,
      :desc => "Password", :arg_name => "PASSWORD"
    c.action do |global_options,options,args|
      if !args.empty?
        ip = args.shift
      else
        raise GLI::BadCommandLine.new("You need to provide the IP of the target system as argument.")
      end

      ImportSshKeysCommand.new.execute(ip, options)
    end
  end

  desc "List available machines and images"
  long_desc <<-LONGDESC
    List virtual machines, base images, and related data
  LONGDESC
  command :list do |c|
    c.action do |global_options,options,args|
      VagrantCommand.setup_environment(@@settings.vagrant_dir)
      ListCommand.new(Cli.settings.kiwi_dir).execute
    end
  end

  desc "Boot custom image file"
  long_desc <<-LONGDESC
    Boot a custom image from the given file IMAGE in a VM not managed by
    Vagrant. You can shut down an image booted this way with `shutdown`.
  LONGDESC
  arg_name "IMAGE"
  command :boot do |c|
    c.action do |global_options,options,args|
      if !args.empty?
        image = File.expand_path(args.shift)
      else
        raise GLI::BadCommandLine.new("You need to provide the name of the image to boot as argument.")
      end
      VagrantCommand.setup_environment(@@settings.vagrant_dir)
      BootCommand.new.execute(image)
    end
  end

  desc "Shutdown custom image"
  long_desc <<-LONGDESC
    Shutdown custom image, which was started with `boot`.
  LONGDESC
  arg_name "IMAGE"
  command :shutdown do |c|
    c.action do |global_options,options,args|
      if !args.empty?
        image = args.shift
      else
        raise GLI::BadCommandLine.new("You need to provide the name of the VM to shutdown as argument.")
      end
      VagrantCommand.setup_environment(@@settings.vagrant_dir)
      ShutdownCommand.new.execute(name)
    end
  end

  def self.host_controller
    CliHostController.new("~/.pennyworth", STDOUT)
  end

  desc "Manage test hosts"
  long_desc <<-LONGDESC
    This subcommand provides the tools to manage existing machines to be used
    as test hosts. Hosts are defined in the configuration file
    `.pennyworth/hosts.yaml`.

    See https://github.com/SUSE/pennyworth#using-existing-hosts for more
    information.
  LONGDESC
  command :host do |c|
    c.desc "Fetch host configuration"
    c.long_desc <<-LONGDESC
      Fetch initial host configuration from a given URL. This can be used to
      share configuration across multiple machines and users. The argument has
      to be the URL to the remote configuration file.
    LONGDESC
    c.arg_name "URL"
    c.command :setup do |sc|
      sc.action do |_, _, args|
        Cli.host_controller.setup(args[0])
      end
    end

    c.desc "List available hosts"
    c.command :list do |sc|
      sc.action do
        Cli.host_controller.list
      end
    end

    c.desc "Lock host"
    c.arg_name "HOST-NAME"
    c.command :lock do |sc|
      sc.action do |_, _, args|
        Cli.host_controller.lock(args[0])
      end
    end

    c.desc "Reset host to defined state"
    c.arg_name "HOST-NAME"
    c.command :reset do |sc|
      sc.action do |_, _, args|
        Cli.host_controller.reset(args[0])
      end
    end

    c.desc "Show information about host"
    c.arg_name "HOST-NAME"
    c.command :info do |sc|
      sc.action do |_, _, args|
        Cli.host_controller.info(args[0])
      end
    end
  end
end
