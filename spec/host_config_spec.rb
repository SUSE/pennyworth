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
    expect(host_config.hosts).to eq(["test_host", "missing_address", "missing_snapshot_id"])
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
      to eq("address" => "host.example.com", "base_snapshot_id" => 5)
  end

  it "returns lock server address" do
    host_config = HostConfig.for_directory(test_data_dir)
    host_config.read
    expect(host_config.lock_server_address).to eq("lock.example.com:9999")
  end

  describe "#setup" do
    it "fails if config file already exists" do
      config_file = nil
      config_dir = given_directory do
        config_file = given_file "hosts.yaml"
      end

      host_config = HostConfig.for_directory(config_dir)

      expect {
        host_config.setup("http://example.com/pennyworth/hosts.yaml")
      }.to raise_error(HostFileError)

      expected_config_file = File.join(test_data_dir, "hosts.yaml")
      expect(File.read(config_file)).to eq(File.read(expected_config_file))
    end

    it "writes initial config file" do
      config_base_dir = given_directory

      config_dir = File.join(config_base_dir, ".pennyworth")

      host_config = HostConfig.for_directory(config_dir)
      host_config.setup("http://example.com/pennyworth/hosts.yaml")

      expected_config = <<EOT
---
include: http://example.com/pennyworth/hosts.yaml
EOT

      expect(File.read(File.join(config_dir, "hosts.yaml"))).
        to eq(expected_config)
    end
  end

  describe "include" do
    it "throws error when included file doesn't exist" do
      host_config = HostConfig.new(given_directory)

      file = <<EOT
---
include: inexistent
EOT

      expect {
        host_config.parse(file)
      }.to raise_error(HostFileError)
    end

    it "takes host from remote file" do
      body = <<EOT
---
hosts:
  test_host_1:
    address: a.example.com
EOT
      stub_request(:get, "http://ci.example.com/pennyworth/hosts.yaml").
        with(headers:
          {
            "Accept" => "*/*",
            "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
            "User-Agent" => "Ruby"
          }).
        to_return(status: 200, body: body, headers: {})

      file = <<EOT
---
include: http://ci.example.com/pennyworth/hosts.yaml
EOT

      host_config = HostConfig.new(given_directory)
      host_config.parse(file)

      expect(host_config.host("test_host_1")["address"]).to eq("a.example.com")
    end

    it "takes host from local file" do
      body = <<EOT
---
hosts:
  test_host_1:
    address: a.example.com
EOT
      stub_request(:get, "http://ci.example.com/pennyworth/hosts.yaml").
        with(headers:
          {
            "Accept" => "*/*",
            "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
            "User-Agent" => "Ruby"
          }).
        to_return(status: 200, body: body, headers: {})

      file = <<EOT
---
include: http://ci.example.com/pennyworth/hosts.yaml
hosts:
  test_host_2:
    address: b.example.com
EOT

      host_config = HostConfig.new(given_directory)
      host_config.parse(file)

      expect(host_config.host("test_host_2")["address"]).to eq("b.example.com")
    end

    it "overwrite host from remote file by host from local file" do
      body = <<EOT
---
hosts:
  test_host_3:
    address: c.example.com
EOT
      stub_request(:get, "http://ci.example.com/pennyworth/hosts.yaml").
        with(headers:
          {
            "Accept" => "*/*",
            "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
            "User-Agent" => "Ruby"
          }).
        to_return(status: 200, body: body, headers: {})

      file = <<EOT
---
include: http://ci.example.com/pennyworth/hosts.yaml
hosts:
  test_host_3:
    address: x.example.com
EOT

      host_config = HostConfig.new(given_directory)
      host_config.parse(file)

      expect(host_config.host("test_host_3")["address"]).to eq("x.example.com")
    end
  end
end
