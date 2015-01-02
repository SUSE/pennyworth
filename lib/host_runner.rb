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

    @locker = LockService.new(host_config.lock_server_address)
  end

  def start
    if !@locker.request_lock(@host_name)
      raise LockError.new("Host '#{@host_name}' already locked")
    end

    @ip
  end

  def stop
    @locker.release_lock(@host_name)
  end
end
