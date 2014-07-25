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

class Cli < Thor

  check_unknown_options!

  default_task :global

  class_option :version, :type => :boolean, :desc => "Show version"
  class_option :verbose, :type => :boolean, :desc => "Verbose mode"
  class_option :silent, :type => :boolean, :desc => "Silent mode"
  class_option :definitions_dir, :type => :string, :aliases => "-d", :required => false, :desc => "Path to the directory containing Veewee and Vagrant definitions"

  def self.exit_on_failure?
    true
  end

  def initialize(args = [], options = {}, config = {})
    super(args, options, config)

    process_global_options(self.options)
  end

  def self.settings
    @@settings
  end

  def self.settings= s
    @@settings = s
  end

  desc "global", "Global options", :hide => true
  def global
    if options[:version]
      log "Pennyworth: #{@@settings.version}"
    else
      Cli.help shell
    end
  end

  desc "setup", "Prepare system for running virtual machines"
  def setup
    SetupCommand.new.execute
  end

  desc "status <vm_name>", "Show status of virtual machine"
  def status(vm_name = nil)
    VagrantCommand.setup_environment(@@settings.vagrant_dir)
    StatusCommand.new.execute(vm_name)
  end

  desc "build-base [image_name]", "Build base images"
  def build_base(image_name = nil)
    begin
      VagrantCommand.setup_environment(@@settings.vagrant_dir)
      BuildBaseCommand.new(Cli.settings.veewee_dir).execute(image_name)
    rescue StandardError => e
      STDERR.puts e
      exit 1
    end
  end

  desc "import-base [image_name]", "Import base images"
  method_option :local, :type => :boolean, :aliases => "-l", :default => false,
    :desc => "Import Vagrant base boxes from locally built VeeWee boxes"
  method_option :url, :type => :string, :aliases => "-u",
    :desc => "URL of the remote server where the images will be imported from"
  def import_base(image_name = nil)
    begin
      VagrantCommand.setup_environment(@@settings.vagrant_dir)
      if options[:local]
        if !options["definitions_dir"]
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
    rescue StandardError => e
      STDERR.puts e
      exit 1
    end
  end

  desc "up <vm_name>", "Start virtual machine"
  method_option :destroy, :type => :boolean, :default => false,
    :desc => "Destroy vagrant instance(s) before starting them."
  def up(vm_name = nil)
    VagrantCommand.setup_environment(@@settings.vagrant_dir)
    UpCommand.new.execute(vm_name, options)
  end

  desc "down <vm_name>", "Stop virtual machine"
  def down(vm_name = nil)
    VagrantCommand.setup_environment(@@settings.vagrant_dir)
    DownCommand.new.execute(vm_name)
  end

  desc "copy-ssh-keys <ip address>", "Copy the public SSH keys to the host for "\
    "easy root access"
  method_option :password, :type => :string, :aliases => "-p"
  def copy_ssh_keys(ip)
    ImportSshKeysCommand.new.execute(ip, options)
  end

  desc "list", "List virtual machines and base images"
  def list
    VagrantCommand.setup_environment(@@settings.vagrant_dir)
    ListCommand.new(Cli.settings.veewee_dir).execute
  end

  desc "boot <path_to_image>", "Boot a custom image in a non vagrant managed VM"
  method_option "name", :type => :string, :aliases => "-n",
    :desc => "Name of image in libvirt"
  def boot(image)
    VagrantCommand.setup_environment(@@settings.vagrant_dir)
    BootCommand.new.execute(image)
  end

  desc "shutdown <path_to_image>", "Shutdown custom image"
  def shutdown(name)
    VagrantCommand.setup_environment(@@settings.vagrant_dir)
    ShutdownCommand.new.execute(name)
  end

  private

  def process_global_options(options)
    @@settings.verbose = !!options[:verbose]
    @@settings.silent = !!options[:silent]
    @@settings.definitions_dir = File.expand_path(options[:definitions_dir]) if options[:definitions_dir]
  end
end
