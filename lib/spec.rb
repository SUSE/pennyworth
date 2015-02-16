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

require "cheetah"
require "libvirt"
require "socket"
require "open-uri"
require "yaml"

require_relative "exceptions"
require_relative "helper"
require_relative "pennyworth_libvirt"
require_relative "vagrant"
require_relative "vagrant_runner"
require_relative "image_runner"
require_relative "host_config"
require_relative "host_runner"
require_relative "lock_service"
require_relative "ssh_keys_importer"
require_relative "vm"
require_relative "spec_profiler"
require_relative "remote_command_runner"
require_relative "settings"
require_relative "local_runner"
require_relative "local_command_runner"

module Pennyworth
  module SpecHelper
    def start_system(opts)
      opts = {
        skip_ssh_setup: false
      }.merge(opts)
      if opts[:box]
        runner = VagrantRunner.new(opts[:box], RSpec.configuration.vagrant_dir)
        password = "vagrant"
      elsif opts[:image]
        runner = ImageRunner.new(opts[:image])
        password = "linux"
      elsif opts[:host]
        config = HostConfig.new(RSpec.configuration.hosts_file)
        config.read
        runner = HostRunner.new(opts[:host], config)
      elsif opts[:local]
        runner = LocalRunner.new(opts.select { |k, _| [:env, :command_map].include?(k) })
      end

      raise "No image specified." unless runner

      system = VM.new(runner)

      # Make sure to stop the machine again when the example group is done
      self.class.after(:all) do
        system.stop
      end

      measure("Boot machine '#{opts[:box] || opts[:image] || opts[:host]}'") do
        system.start
      end
      if !opts[:skip_ssh_setup] && !opts[:host] && !opts[:local]
        SshKeysImporter.import(system.ip, password)
      end

      system
    end
  end
end

RSpec.configure do |config|
  defaults = Settings.new
  config.include(Pennyworth::SpecHelper)
  config.add_setting :pennyworth_mode, default: false
  config.add_setting :vagrant_dir, default: defaults.vagrant_dir
  config.add_setting :hosts_file, default: File.join(defaults.definitions_dir, "/hosts.yaml")

  config.before(:all) do
    unless RSpec.configuration.pennyworth_mode
      Pennyworth::Libvirt.ensure_libvirt_env_started
    end
  end
end
