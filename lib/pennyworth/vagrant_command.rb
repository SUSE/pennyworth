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

module Pennyworth
  class VagrantCommand < Command
    attr_reader :vagrant

    def initialize
      @vagrant = Pennyworth::Vagrant.new(Pennyworth::Cli.settings.vagrant_dir)
    end

    def self.parse_status output
      result = []
      parsing_vms = false
      output.each_line do |line|
        line.strip!
        if line.empty?
          break if parsing_vms
          parsing_vms = true
        elsif parsing_vms
          line =~ /^(.*?)\s+(.*)$/
          vm_name = $1
          vm_state = $2
          if vm_state =~ /running/
            vm_name += " (running)"
          end
          result.push vm_name
        end
      end
      result
    end

    def self.setup_environment(dir)
      if !File.exists?(File.join(dir, "Vagrantfile"))
        vagrant = Pennyworth::Vagrant.new(dir)
        FileUtils.mkdir_p(dir)
        vagrant.run("init")
      end
    end

    def up(vm_name, destroy)
      Pennyworth::Libvirt.ensure_libvirt_env_started

      if vm_name
        log "Starting VM #{vm_name}..."
        @vagrant.run "destroy", vm_name if destroy
        @vagrant.run "up", vm_name
      else
        log "Starting test environment..."
        @vagrant.run "destroy" if destroy
        @vagrant.run "up"
      end
    end

    def down(vm_name)
      if vm_name
        log "Stopping VM #{vm_name}..."
        @vagrant.run "halt", vm_name
      else
        log "Stopping test environment..."
        @vagrant.run "halt"
      end
    end

    def env_clean?
      status = @vagrant.run "status", :stdout => :capture

      return status.index("running").nil?
    end

    def reset(vm_name)
      if vm_name
        log "Resetting VM #{vm_name}..."
        @vagrant.run "destroy", vm_name
      else
        log "Resetting test environment..."
        @vagrant.run "destroy"
      end
    end

    def ssh(vm_name, cmd, stdout = nil)
      if vm_name
        @vagrant.run "ssh", vm_name, "-c", cmd, :stdout => stdout
      else
        @vagrant.run "ssh", "-c", cmd, :stdout => stdout
      end
    end

    def list
      boxes = @vagrant.run "box", "list", :stdout => :capture
      boxes.split("\n")
    end

    def status
      Pennyworth::VagrantCommand.parse_status( @vagrant.run "status", :stdout => :capture )
    end

    def destroy
      @vagrant.run "destroy"
    rescue Cheetah::ExecutionFailed
    end

    def add_box box, box_path
      @vagrant.run "box", "add", box, box_path, "--force"
    end
  end
end
