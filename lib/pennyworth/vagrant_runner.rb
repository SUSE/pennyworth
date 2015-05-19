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
  class VagrantRunner < Runner
    def initialize(box, vagrant_dir, username)
      @box = box
      @username = username
      @vagrant = Vagrant.new(vagrant_dir)
    end

    def start
      @vagrant.run "destroy", @box
      @vagrant.run "up", @box

      ip = @vagrant.ssh_config(@box)[@box]["HostName"]
      @command_runner = RemoteCommandRunner.new(ip, @username)

      ip
    end

    def stop
      @vagrant.run "halt", @box
    end

    def cleanup_directory(_dir)
      # The machine will be reset anyway after the tests, so this is is a NOP
    end
  end
end
