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
  class SetupCommand < Command
    def initialize
      super

      @user = ENV["LOGNAME"]
    end

    def execute
      # Install dependencies
      show_warning_for_unsupported_platforms
      install_packages
      reload_udev_rules
      install_vagrant_plugin

      # Set up permissions
      add_user_to_groups
      disable_libvirt_policykit_auth
      allow_libvirt_access
      allow_qemu_kvm_access
      allow_arp_access

      # Enable required services
      enable_services
    end

    def show_warning_for_unsupported_platforms
      supported_os = ["openSUSE 13.2", "SLES 12"]

      os_release = read_os_release_file

      if os_release
        version = os_release[/^VERSION_ID="(.*)"/, 1]
        distribution = os_release[/^NAME="(.*)"/, 1]
      end

      if !os_release || !supported_os.include?("#{distribution} #{version}")
        log "Warning: Pennyworth is not tested upstream on this platform. " \
          "Use at your own risk."
      end
    end

    def read_os_release_file
      os_release_file = "/etc/os-release"
      File.read(os_release_file) if File.exist?(os_release_file)
    end

    def vagrant_installed?
      vagrant = Cheetah.run "rpm", "-q", "vagrant", stdout: :capture
      @vagrant_version = vagrant.lines.select { |plugin| plugin.start_with?("vagrant") }

      !vagrant.match(/vagrant-[1-]\.[7-]\.[2-]/).nil?
    end

    def vagrant_libvirt_installed?
      vagrant_libvirt = Cheetah.run "vagrant", "plugin", "list", stdout: :capture
      @vagrant_libvirt_version = vagrant_libvirt.lines.select { |plugin|
        plugin.start_with?("vagrant-libvirt")
      }

      !vagrant_libvirt.match(/vagrant-libvirt \(\d\.\d\.29|[3-9]\d\)/).nil?
    end

    private

    def zypper_install(package)
      Cheetah.run(
        "sudo",
        "zypper",
        "--non-interactive",
        "install",
        "--auto-agree-with-licenses",
        "--name",
        package
      )
    end

    def install_packages
      log "Installing packages:"

      packages = config["packages"]["local"]

      if config["packages"][base_system]
        packages += config["packages"][base_system]
      end

      packages.each do |name|
        log "  * Installing #{name}..."
        zypper_install(name)
      end

      config["packages"]["remote"].each do |url|
        if url.match(/vagrant_/) && !vagrant_installed?
          log "  * Downloading and installing #{url}..."
          zypper_install(url)
        else
          log "  * You already have a valid version of #{@vagrant_version[0]}"
        end
      end
    end

    # The kvm package does come with a udev rule file to adjust ownership of
    # /dev/kvm. However, the installation of the package does not trigger a
    # reload of the udev rules. In order for /dev/kvm to have the right
    # ownership we need to reload the udev rules ourself.
    def reload_udev_rules
      log "Reloading udev rules"
      Cheetah.run "sudo", "/sbin/udevadm", "control", "--reload-rules"
      Cheetah.run "sudo", "/sbin/udevadm", "trigger"
    end

    def install_vagrant_plugin
      if !vagrant_libvirt_installed?
        log "Installing libvirt plugin for Vagrant..."
        Cheetah.run "vagrant", "plugin", "install", "vagrant-libvirt"
      else
        log "  * You already have a valid version of #{@vagrant_libvirt_version[0]}"
      end
    end

    def add_user_to_groups
      log "Adding user #@user to groups:"

      ["libvirt", "qemu", "kvm"].each do |group|
        log "  * Adding to group #{group}..."
        Cheetah.run "sudo", "/usr/sbin/usermod", "-a", "-G", group, @user
      end
    end

    # Without this, PlicyKit would pop-up a dialog asking for root password every
    # time you do something with libvirt as a normal user. This would break the
    # setup workflow and fail on headless machines.
    def disable_libvirt_policykit_auth
      log "Disabling PolicyKit authentication for libvirt..."

      policykit_config = File.dirname(__FILE__) + "/../../../files/99-libvirt.rules"
      Cheetah.run "sudo", "cp", policykit_config, "/etc/polkit-1/rules.d/99-libvirt.rules"
    end

    def allow_libvirt_access
      log "Allowing libvirt access for normal users..."

      adapt_config_file "/etc/libvirt/libvirtd.conf",
        :unix_sock_group    => "libvirt",
        :unix_sock_ro_perms => "0777",
        :unix_sock_rw_perms => "0770",
        :auth_unix_rw       => "none",
        # By default, libvirt logs to syslog. We'd like to have the logs
        # separated.
        :log_outputs        => "1:file:/var/log/libvirt/libvirt.log"
    end

    def allow_qemu_kvm_access
      log "Allowing qemu-kvm access for user #@user..."

      adapt_config_file "/etc/libvirt/qemu.conf",
        :user  => @user,
        :group => "qemu"
    end

    # Pennyworth build fails because Pennyworth can't find arp when run as a normal user.
    # This is a crude workaround.
    def allow_arp_access
      log "Making arp command available for normal users..."

      Cheetah.run "sudo", "ln", "-sf", "/sbin/arp", "/usr/bin"
    end

    def adapt_config_file(file, adaptations)
      # Create a backup.
      Cheetah.run "sudo", "cp", file, "#{file}.pennyworth_save"

      # Create a temporary copy with permissions that allow us to modify it.
      temp_file = "/tmp/#{File.basename(file)}.pennyworth"
      Cheetah.run "sudo", "cp", file, temp_file
      Cheetah.run "sudo", "chmod", "a+rw", temp_file

      # Do the adaptations.
      content = File.read(temp_file)
      adaptations.each_pair do |key, value|
        regexp_uncommented = /^(\s*)#{key}(\s*)=(\s*).*$/
        regexp_commented   = /^(\s*)\#?#{key}(\s*)=(\s*).*$/
        replacement = "\\1#{key}\\2=\\3#{value.inspect}"

        # We need to be careful here because sometimes there are both commented
        # and uncommented lines in the file. In that case, we want to modify the
        # first uncommented line and keep the commented ones intact. On the other
        # hand, if there are just commented lines, we want to uncomment and modify
        # the first one.
        if content =~ regexp_uncommented
          content.sub!(regexp_uncommented, replacement)
        elsif content =~ regexp_commented
          content.sub!(regexp_commented, replacement)
        else
          raise "#{file} No #{key.inspect} option to adapt."
        end
      end
      File.write(temp_file, content)

      # Replace the original file with the temporary copy, keep its permissions
      # intact.
      permissions = Cheetah.run(
        "sudo",
        "stat",
        "--printf",
        "%a",
        file,
        :stdout => :capture
      )
      Cheetah.run "sudo", "mv", temp_file, file
      Cheetah.run "sudo", "chmod", permissions, file
    end

    def enable_services
      ["libvirtd", "dnsmasq"].each do |service|
        Cheetah.run "sudo", "systemctl", "enable", service
      end
    end

    def base_system
      Cheetah.run(["lsb_release", "--release"], :stdout => :capture).split[1]
    end
  end
end
