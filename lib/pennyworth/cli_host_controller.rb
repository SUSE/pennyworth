# Copyright (c) 2013-2015 SUSE LLC
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
  class CliHostController
    def initialize(config_dir, output)
      @config_dir = config_dir
      @out = output
    end

    def setup(url)
      if !url
        raise GLI::BadCommandLine.new("Please provide a URL argument")
      end

      @out.puts "Setup from '#{url}'"
      begin
        HostConfig.for_directory(@config_dir).setup(url)
      rescue HostFileError => e
        @out.puts "Error: #{e}"
      end
    end

    def list
      host_config.hosts.each do |host_name|
        host = host_config.host(host_name)
        out = "#{host_name}"
        attributes = []
        if host['address']
          attributes.push("address: #{host['address']}")
        end
        if host['base_snapshot_id']
          attributes.push("base snapshot id: #{host['base_snapshot_id']}")
        end
        if !attributes.empty?
          out += " (" + attributes.join(", ") + ")"
        end
        @out.puts(out)
      end
    end

    def lock(host_name)
      check_host(host_name)

      locker = LockService.new(host_config.lock_server_address)
      if locker.request_lock(host_name)
        @out.puts "Lock acquired for host '#{host_name}'"

        locker.keep_lock
      else
        @out.puts "Failed to acquire lock for host '#{host_name}': " +
          "#{locker.info(host_name)}"
      end
    end

    def info(host_name)
      check_host(host_name)

      locker = LockService.new(host_config.lock_server_address)
      @out.puts(locker.info(host_name))
    end

    def reset(host_name)
      check_host(host_name)

      runner = HostRunner.new(host_name, host_config)
      runner.start
      runner.cleanup
    end

    private

    def check_host(host_name)
      if !host_name
        raise GLI::BadCommandLine.new("Please provide a host name argument")
      end

      if !host_config.host(host_name)
        raise LockError.new("Host name #{host_name} doesn't exist in " +
          "configuration file '#{host_config.config_file}'")
      end
    end

    def host_config
      return @host_config if @host_config

      @host_config = HostConfig.for_directory(@config_dir)
      @host_config.read

      @host_config
    end
  end
end
