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

class HostConfig
  attr_reader :hosts

  def initialize(config_dir)
    @config_dir = File.expand_path(config_dir)
  end

  def config_file
    File.join(@config_dir, "hosts.yaml")
  end

  def read
    yaml = YAML.load_file(config_file)
    if yaml
      @hosts = yaml.keys
    else
      raise HostFileError.new("Could not parse YAML in file '#{config_file}'")
    end
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

    File.open(config_file, "w") do |f|
      f.write(body)
    end
  end
end
