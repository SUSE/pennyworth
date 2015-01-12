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

class HostConfig
  attr_reader :config_file, :lock_server_address

  def self.for_directory(config_dir)
    HostConfig.new(File.join(config_dir, "hosts.yaml"))
  end

  def initialize(config_file)
    @config_file = File.expand_path(config_file)
  end

  def parse(yaml_string)
    yaml = YAML.load(yaml_string)
    if !yaml
      raise HostFileError.new("Could not parse YAML in file '#{config_file}'")
    end

    if yaml["include"]
      begin
        open(yaml["include"], "rb") do |u|
          parse(u.read)
        end
      rescue OpenURI::HTTPError, Errno::ENOENT
        raise HostFileError.new("Unable to include '#{yaml["include"]}'")
      end
    end

    if yaml["hosts"]
      if !@hosts
        @hosts = yaml["hosts"]
      else
        yaml["hosts"].each do |key, value|
          @hosts[key] = value
        end
      end
    end

    if yaml["lock_server_address"]
      @lock_server_address = yaml["lock_server_address"]
    end
  end

  def read
    parse(File.read(config_file))
  end

  def hosts
    @hosts.keys
  end

  def host(host_name)
    @hosts[host_name]
  end

  def fetch(url)
    file_url = url + "/pennyworth/hosts.yaml"
    body = nil
    begin
      open(file_url, "rb") do |u|
        body = u.read
      end
    rescue OpenURI::HTTPError
      raise HostFileError.new("Unable to fetch from '#{file_url}'")
    end

    FileUtils.mkdir_p(File.dirname(config_file))
    File.open(config_file, "w") do |f|
      f.write(body)
    end
  end
end
