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

class HostRunner
  def initialize(host_name, config_file)
    @host_name = host_name

    host_config = HostConfig.new(config_file)
    host_config.read
    host = host_config.host(host_name)
    if !host
      raise InvalidHostError.new("Invalid host name: '#{host_name}'")
    end
    @ip = host["address"]
    @base_snapshot_id = host["base_snapshot_id"]

    @locker = LockService.new(host_config.lock_server_address)
  end

  def start
    if !@locker.request_lock(@host_name)
      raise LockError.new("Host '#{@host_name}' already locked")
    end

    connect
    @ip
  end

  def cleanup
    run_command "snapper", "create", "-c", "number", "--pre-number", @base_snapshot_id.to_s,
      "--description", "pennyworth_snapshot"
    run_command "snapper", "undochange", "#{@base_snapshot_id}..0"
    run_command "bash", "-c", "reboot &"
  end

  def stop
    cleanup if @connected
    @locker.release_lock(@host_name)
  end

  private

  # Tries to connect to the remote system as root (without a password or passphrase)
  # and raises an Machinery::Errors::SshConnectionFailed exception when it's not successful.
  def connect
    Cheetah.run "ssh", "-q", "-o", "BatchMode=yes", "root@#{@ip}"
    @connected = true
  rescue Cheetah::ExecutionFailed
    raise SshConnectionFailed.new(
      "Could not establish SSH connection to host '#{@ip}'. Please make sure that " \
      "you can connect non-interactively as root, e.g. using ssh-agent.\n\n" \
      "To copy your default ssh key to the machine run:\n" \
      "ssh-copy-id root@#{@ip}"
    )
  end

  def run_command(*cmd)
    Cheetah.run(
      "ssh",
      "-o",
      "UserKnownHostsFile=/dev/null",
      "-o",
      "StrictHostKeyChecking=no",
      "root@#{@ip}",
      "LC_ALL=C",
      *cmd
    )
  end
end
