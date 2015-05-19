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

describe Pennyworth::HostRunner do
  let(:host_config) {
    config = Pennyworth::HostConfig.for_directory(test_data_dir)
    config.read
    config
  }
  let(:runner) {
    Pennyworth::HostRunner.new("test_host", host_config, "root")
  }

  it_behaves_like "a runner"

  describe "#initialize" do
    it "fails with error, if host is not known" do
      expect {
        Pennyworth::HostRunner.new("invalid_name", host_config, "root")
      }.to raise_error(Pennyworth::InvalidHostError)
    end

    it "fails with error, if address is not set" do
      expect {
        Pennyworth::HostRunner.new("missing_address", host_config, "root")
      }.to raise_error(Pennyworth::InvalidHostError)
    end

    it "fails with error, if base_snapshot_id is not set" do
      expect {
        Pennyworth::HostRunner.new("missing_snapshot_id", host_config, "root")
      }.to raise_error(Pennyworth::InvalidHostError)
    end
  end

  describe "#start" do
    it "returns the IP address of the started system" do
      expect_any_instance_of(Pennyworth::LockService).to receive(:request_lock).
        and_return(true)
      expect(runner).to receive(:connect)
      expect(runner).to receive(:check_cleanup_capabilities)

      expect(runner.start).to eq("host.example.com")
    end
  end

  describe "#stop" do
    before(:each) do
      expect_any_instance_of(Pennyworth::LockService).to receive(:release_lock).
        and_return(true)
    end

    it "triggers a cleanup when the host was connected" do
      runner.instance_variable_set(:@connected, true)
      expect(runner).to receive(:cleanup)

      runner.stop
    end

    it "does not trigger a cleanup when SKIP_HOST_CLEANUP is set" do
      runner.instance_variable_set(:@connected, true)
      expect(runner).to_not receive(:cleanup)

      with_env "SKIP_HOST_CLEANUP" => "true" do
        runner.stop
      end
    end
  end

  describe "#cleanup" do
    it "cleans up the host" do
      runner.instance_variable_set(:@connected, true)
      runner.instance_variable_set(:@cleaned_up, false)
      command_runner = double(:run)
      expect(command_runner).to receive(:run).at_least(:once)
      expect(Pennyworth::RemoteCommandRunner).to receive(:new).and_return(command_runner)

      runner.cleanup
    end
    it "does not clean up when the host was not connected" do
      runner.instance_variable_set(:@connected, false)
      runner.instance_variable_set(:@cleaned_up, false)
      expect(Pennyworth::RemoteCommandRunner).to_not receive(:new)

      runner.cleanup
    end

    it "does not clean up when the host was already cleaned up" do
      runner.instance_variable_set(:@connected, true)
      runner.instance_variable_set(:@cleaned_up, true)
      expect(Pennyworth::RemoteCommandRunner).to_not receive(:new)

      runner.cleanup
    end
  end
end
