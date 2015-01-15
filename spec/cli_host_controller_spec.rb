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

describe CliHostController do
  use_given_filesystem

  context "no configuration" do
    before(:each) do
      @config_dir = given_directory
      out = double
      allow(out).to receive(:puts)
      @controller = CliHostController.new(@config_dir, out)
    end

    describe "#setup" do
      it "raises error when no argument is given" do
        expect {
          @controller.setup(nil)
        }.to raise_error(GLI::BadCommandLine)
      end

      it "fetches configuration file" do
        stub_request(:get, "http://remote.example.com/pennyworth/hosts.yaml").
          with(:headers => {
            "Accept" => "*/*",
            "Accept-Encoding" => "gzip;q=1.0,deflate;q=0.6,identity;q=0.3",
            "User-Agent" => "Ruby"
          }).
          to_return(status: 200, body: "xx", headers: {})

        config_file = File.join(@config_dir, "hosts.yaml")
        expect(File.exist?(config_file)).to be(false)
        @controller.setup("http://remote.example.com")
        expect(File.exist?(config_file)).to be(true)
      end
    end
  end

  context "existing configuration" do
    before(:each) do
      @config_dir = given_directory do
        given_file("hosts.yaml")
      end
      @out = double
      @controller = CliHostController.new(@config_dir, @out)
    end

    describe "#list" do
      it "lists host" do
        expect(@out).to receive(:puts).
          with("test_host (address: host.example.com, base snapshot id: 5)")
        expect(@out).to receive(:puts).
          with("missing_address (base snapshot id: 5)")
        expect(@out).to receive(:puts).
          with("missing_snapshot_id (address: host.example.com)")

        @controller.list
      end
    end

    describe "#lock" do
      it "raises error when no argument is given" do
        expect {
          @controller.lock(nil)
        }.to raise_error(GLI::BadCommandLine)
      end

      it "raises error when host is not in configuration file" do
        expect {
          @controller.lock("invalid name")
        }.to raise_error(LockError)
      end

      it "acquires lock for host" do
        expect_any_instance_of(LockService).to receive(:request_lock).
          with("test_host").and_return(true)
        expect(@out).to receive(:puts).with(/test_host/)
        expect_any_instance_of(LockService).to receive(:keep_lock)

        @controller.lock("test_host")
      end

      it "fails to acquire lock for host" do
        expect_any_instance_of(LockService).to receive(:request_lock).
          with("test_host").and_return(false)
        expect_any_instance_of(LockService).to receive(:info).
          with("test_host").and_return("'test_host' locked by 1.2.3.4")
        expect(@out).to receive(:puts).with(/test_host/)
        expect_any_instance_of(LockService).to_not receive(:keep_lock)

        @controller.lock("test_host")
      end
    end
  end
end
