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
  class Libvirt
    LIBVIRT_NET_NAME  = "default"
    LIBVIRT_POOL_NAME = "default"

    class << self
      def ensure_libvirt_env_started
        # The check here is unnecessary for technical reasons ("sysctl start" does
        # not fail if the service is already running), but it avoids an unnecessary
        # sudo password prompt.
        libvirtd_start unless libvirtd_active?

        libvirt_net_start unless libvirt_net_active?

        # As default pool is not always available but gets sometimes created by
        # tools like virt-manager, we need to create it ourself if it does not yet
        # exist.
        libvirt_pool_create unless libvirt_pool_exists?
      end

      private

      def libvirtd_start
        Cheetah.run "sudo", "systemctl", "start", "libvirtd"

        sleep 0.1 until File.exists?("/var/run/libvirt/libvirt-sock")
      end

      def libvirtd_active?
        output = Cheetah.run "systemctl", "show", "--property", "ActiveState", "libvirtd", :stdout => :capture

        output == "ActiveState=active"
      end

      def libvirt_net_start
        Cheetah.run "virsh", "-c", "qemu:///system", "net-start", LIBVIRT_NET_NAME
      end

      def libvirt_net_active?
        output = with_c_locale do
          Cheetah.run "virsh", "-c", "qemu:///system", "net-list", "--all", :stdout => :capture
        end

        # The output looks like this:
        #
        #    Name                 State      Autostart     Persistent
        #   ----------------------------------------------------------
        #    default              active     no            yes
        #    vagrant0             active     yes           yes
        #
        output.split("\n")[2..-1].find do |line|
          line =~ /^\s*#{LIBVIRT_NET_NAME}\s+active/
        end
      end

      def libvirt_pool_create
        pool_config_file = File.dirname(__FILE__) + "/../files/pool-default.xml"
        Cheetah.run "virsh", "-c", "qemu:///system", "pool-create", pool_config_file
      end

      def libvirt_pool_exists?
        output = with_c_locale do
          Cheetah.run "virsh", "-c", "qemu:///system", "pool-list", "--all", :stdout => :capture
        end

        # The output looks like this:
        #
        #   Name                 State      Autostart
        #   -----------------------------------------
        #   default              active     no
        #
        output.split("\n")[2..-1].find { |line| line =~ /^#{LIBVIRT_POOL_NAME}/ }
      end
    end
  end
end