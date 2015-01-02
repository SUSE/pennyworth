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

require "spec_helper"

include GivenFilesystemSpecHelpers

describe HostConfig do
  use_given_filesystem

  it "creates config object for config dir" do
    config_dir = given_directory
    host_config = HostConfig.for_directory(config_dir)
    expect(host_config.config_file).to eq(File.join(config_dir, "hosts.yaml"))
  end

  it "reads config file" do
    host_config = HostConfig.for_directory(test_data_dir)
    host_config.read
    expect(host_config.hosts).to eq(["test_host"])
  end

  it "raises error when it cannot read the file" do
    config_dir = given_directory
    File.write(File.join(config_dir, "hosts.yaml"), "")

    host_config = HostConfig.for_directory(config_dir)

    expect {
      host_config.read
    }.to raise_error HostFileError
  end

  it "returns host" do
    host_config = HostConfig.for_directory(test_data_dir)
    host_config.read
    expect(host_config.host("test_host")).
      to eq("address" => "host.example.com")
  end

  it "returns lock server address" do
    host_config = HostConfig.for_directory(test_data_dir)
    host_config.read
    expect(host_config.lock_server_address).to eq("lock.example.com:9999")
  end

  it "fetches remote config" do
    body = <<EOT
---
hosts:
  test_host:
    address: host.example.com
EOT
    stub_request(:get, "http://remote.example.com/pennyworth/hosts.yaml").
      with(:headers => {
        "Accept" => "*/*",
        "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
        "User-Agent" => "Ruby"
      }).
      to_return(status: 200, body: body, headers: {})

    config_dir = given_directory

    host_config = HostConfig.for_directory(config_dir)
    host_config.fetch("http://remote.example.com")

    expect(File.read(File.join(config_dir, "hosts.yaml"))).to eq(body)
  end
end
