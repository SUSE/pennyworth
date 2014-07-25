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
require "tempfile"
require "libvirt"

require_relative "exceptions"
require_relative "helper"
require_relative "pennyworth_libvirt"
require_relative "vagrant"
require_relative "vagrant_runner"
require_relative "image_runner"
require_relative "ssh_keys_importer"
require_relative "vm"
require_relative "spec_profiler"

module Pennyworth
  module SpecHelper
    def start_system(opts)
      if opts[:box]
        runner = VagrantRunner.new(opts[:box], RSpec.configuration.vagrant_dir)
        password = "vagrant"
      elsif opts[:image]
        runner = ImageRunner.new(opts[:image])
        password = "linux"
      end

      raise "No image specified." unless runner

      system = VM.new(runner)

      # Make sure to stop the machine again when the example group is done
      self.class.after(:all) do
        system.stop
      end

      measure("Boot machine '#{opts[:box] || opts[:image]}'") do
        system.start
      end
      SshKeysImporter.import(system.ip, password)

      system
    end
  end
end

RSpec.configure do |config|
  config.include(Pennyworth::SpecHelper)
  config.add_setting :pennyworth_mode, default: false
  config.add_setting :vagrant_dir, default: ""

  config.before(:all) do
    unless RSpec.configuration.pennyworth_mode
      Pennyworth::Libvirt.ensure_libvirt_env_started
    end
  end
end
