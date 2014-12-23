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
          with(:headers => {'Accept'=>'*/*', 'Accept-Encoding'=>'gzip;q=1.0,deflate;q=0.6,identity;q=0.3', 'User-Agent'=>'Ruby'}).
          to_return(:status => 200, :body => "xx", :headers => {})

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
        expect(@out).to receive(:puts).with("test_host")

        @controller.list
      end
    end

    describe "#lock" do
      it "raises error when no argument is given" do
        expect {
          @controller.lock(nil)
        }.to raise_error(GLI::BadCommandLine)
      end

      it "acquires lock for host" do
        expect(@out).to receive(:puts).with(/to be implemented/)

        expect(@controller.lock("test_host")).to be(true)
      end
    end
  end
end
