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

class VagrantRunner
  def initialize(box, vagrant_dir, provider)
    @box = box
    @vagrant = Vagrant.new(vagrant_dir, provider)
  end

  def start
    @vagrant.run "destroy", "-f", @box
    @vagrant.run "up", @box

    @vagrant.ssh_config(@box)[@box]["HostName"]
  end

  def stop
    @vagrant.run "halt", @box
  end
end
