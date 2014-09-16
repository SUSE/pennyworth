# Copyright (c) 2013-2014 SUSE LLC
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

  program_desc 'A tool for running integration tests inside a network of virtual machines'
  preserve_argv(true)
  @version = Pennyworth::VERSION
  switch :version, :negatable => false, :desc => "Show version"
  switch [:help, :h], :negatable => false, :desc => "Show help"
  switch :verbose, :negatable => false, :desc => "Verbose"
  switch [:silent], :negatable => false, :desc => "Silent mode"
  flag [:definitions_dir, :d], :desc => "Path to the directory containing Veewee and Vagrant definitions", :arg_name => "DEFINITIONS_DIR"

  pre do |global_options,command,options,args|
    @@settings.verbose = !!global_options[:verbose]
    @@settings.silent = !!global_options[:silent]
    @@settings.definitions_dir = File.expand_path(
      global_options[:definitions_dir]
    ) if global_options[:definitions_dir]
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
    when Cheetah::ExecutionFailed
      STDERR.puts e.to_s
      exit 1
    else
      STDERR.puts e.to_s
      exit 1
    end

    true
  end


  def self.shift_arg(args, name)
    if !res = args.shift
      raise GLI::BadCommandLine.new("Pennyworth was called with missing argument #{name}.")
    end
    res
  end

  def self.settings
    @@settings
  end

  def self.settings= s
    @@settings = s
  end

  desc "setup"
  long_desc <<-LONGDESC
    Prepare system for running virtual machines
  LONGDESC
  command :setup do |c|
    c.action do |global_options,options,args|
      SetupCommand.new.execute
    end
  end

  desc "status <vm_name>"
  long_desc <<-LONGDESC
    Show status of virtual machine
  LONGDESC
  arg_name "VM_NAME"
  command :status do |c|
    c.action do |global_options,options,args|
      vm_name = shift_arg(args, "VM_NAME")
      VagrantCommand.setup_environment(@@settings.vagrant_dir)
      StatusCommand.new.execute(vm_name)
    end
  end

  desc "build-base [image_name]"
  long_desc <<-LONGDESC
    Build base images
  LONGDESC
  arg_name "IMAGE_NAME"
  command "build-base" do |c|
    c.action do |global_options,options,args|
      image_name = shift_arg(args, "IMAGE_NAME")
      VagrantCommand.setup_environment(@@settings.vagrant_dir)
      BuildBaseCommand.new(Cli.settings.veewee_dir).execute(image_name)
    end
  end

  desc "import-base [image_name]"
  long_desc <<-LONGDESC
    Import base images
  LONGDESC
  arg_name "IMAGE_NAME"
  command "import-base" do |c|
    c.flag [:url, :u], :type => String, :required => false,
      :desc => "URL of the remote server where the images will be imported from", :arg_name => "URL"
    c.switch [:local, :l], :default_value => false, :required => false, :negatable => false,
      :desc => "Import Vagrant base boxes from locally built VeeWee boxes"
    c.action do |global_options,options,args|
      image_name = shift_arg(args, "IMAGE_NAME")
      VagrantCommand.setup_environment(@@settings.vagrant_dir)
      if options[:local]
        if !global_options["definitions_dir"]
          STDERR.puts "You need to specify a definitions directory when using --local."
          exit 1
        end
        veewee_dir = Cli.settings.veewee_dir
        opts = {
          local: true
        }
      else
        if !options[:url]
          STDERR.puts "You need to specify a URL when not using --local."
          exit 1
        end
        veewee_dir = File.expand_path("~/.pennyworth/veewee")
        remote_url = options[:url]
        opts = {
          local: false,
        }
      end
      ImportBaseCommand.new(veewee_dir, remote_url).execute(image_name, opts)
    end
  end

  desc "up <vm_name>"
  long_desc <<-LONGDESC
    Start virtual machine
  LONGDESC
  arg_name "VM_NAME"
  command :up do |c|
    c.switch [:destroy], :default_value => false, :required => false, :negatable => false,
      :desc => "Destroy vagrant instance(s) before starting them."
    c.action do |global_options,options,args|
      vm_name = shift_arg(args, "VM_NAME")
      VagrantCommand.setup_environment(@@settings.vagrant_dir)
      UpCommand.new.execute(vm_name, options)
    end
  end

  desc "down <vm_name>"
  long_desc <<-LONGDESC
    Stop virtual machine
  LONGDESC
  arg_name "VM_NAME"
  command :down do |c|
    c.action do |global_options,options,args|
      vm_name = shift_arg(args, "VM_NAME")
      VagrantCommand.setup_environment(@@settings.vagrant_dir)
      DownCommand.new.execute(vm_name)
    end
  end

  desc "copy-ssh-keys <ip address>"
  long_desc <<-LONGDESC
    Copy the public SSH keys to the host for easy root access
  LONGDESC
  arg_name "IP"
  command :copy_ssh_keys do |c|
    c.flag [:password, :p], :type => String, :required => false,
      :desc => "Password", :arg_name => "PASSWORD"
    c.action do |global_options,options,args|
      ip = shift_arg(args, "IP")
      ImportSshKeysCommand.new.execute(ip, options)
    end
  end

  desc "list"
  long_desc <<-LONGDESC
    List virtual machines and base images
  LONGDESC
  command :list do |c|
    c.action do |global_options,options,args|
      VagrantCommand.setup_environment(@@settings.vagrant_dir)
      ListCommand.new(Cli.settings.veewee_dir).execute
    end
  end

  desc "boot <path_to_image>"
  long_desc <<-LONGDESC
    "Boot a custom image in a non vagrant managed VM"
  LONGDESC
  arg_name "IMAGE"
  command :boot do |c|
    c.action do |global_options,options,args|
      image = shift_arg(args, "IMAGE")
      VagrantCommand.setup_environment(@@settings.vagrant_dir)
      BootCommand.new.execute(image)
    end
  end

  desc "shutdown <path_to_image>"
  long_desc <<-LONGDESC
    Shutdown custom image
  LONGDESC
  arg_name "NAME"
  command :shutdown do |c|
    c.action do |global_options,options,args|
      image = shift_arg(args, "IMAGE")
      VagrantCommand.setup_environment(@@settings.vagrant_dir)
      ShutdownCommand.new.execute(name)
    end
  end
end
