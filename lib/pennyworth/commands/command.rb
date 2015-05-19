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
  class Command

    def initialize
      Cheetah.default_options = { :logger => logger }
    end

    def config
      @config ||= YAML.load_file(File.dirname(__FILE__) + "/../../../config/setup.yml")
    end

    def logger
      @logger ||= Logger.new("/tmp/pennyworth.log")
    end

    private

    def print_ssh_config(vagrant, vm_name)
      config = vagrant.ssh_config(vm_name)

      config.each_pair do |host, host_config|
        puts "#{host}\t#{host_config["HostName"]}"
      end
    end
  end
end
