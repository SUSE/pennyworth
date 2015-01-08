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

describe HostRunner do
  let(:runner) {
    HostRunner.new("test_host", File.join(test_data_dir, "hosts.yaml"))
  }

  it_behaves_like "a runner"

  describe "#initialize" do
    it "fails with error, if host is not known" do
      expect {
        HostRunner.new("invalid_name", File.join(test_data_dir, "hosts.yaml"))
      }.to raise_error(InvalidHostError)
    end

    it "fails with error, if address is not set" do
      expect {
        HostRunner.new("missing_address", File.join(test_data_dir, "hosts.yaml"))
      }.to raise_error(InvalidHostError)
    end

    it "fails with error, if base_snapshot_id is not set" do
      expect {
        HostRunner.new("missing_snapshot_id", File.join(test_data_dir, "hosts.yaml"))
      }.to raise_error(InvalidHostError)
    end
  end

  describe "#start" do
    it "returns the IP address of the started system" do
      expect_any_instance_of(LockService).to receive(:request_lock).
        and_return(true)
      expect(runner).to receive(:connect)

      expect(runner.start).to eq("host.example.com")
    end
  end

  describe "#stop" do
    before(:each) do
      expect_any_instance_of(LockService).to receive(:release_lock).
        and_return(true)
    end

    it "triggers a cleanup when the host was connected" do
      runner.instance_variable_set(:@connected, true)
      expect(runner).to receive(:cleanup)

      runner.stop
    end

    it "does not trigger a cleanup when the host was not connected" do
      runner.instance_variable_set(:@connected, false)
      expect(runner).to_not receive(:cleanup)

      runner.stop
    end

    it "does not trigger a cleanup when SKIP_CLEANUP is set" do
      runner.instance_variable_set(:@connected, true)
      expect(runner).to_not receive(:cleanup)

      with_env "SKIP_CLEANUP" => "true" do
        runner.stop
      end
    end
  end
end
