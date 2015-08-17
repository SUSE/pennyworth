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

require "pennyworth/spec"

describe Pennyworth::SpecHelper do
  let(:system_one) { "openSUSE_13.1" }
  let(:system_two) { "openSUSE_12.3" }
  let(:image_one) { "/path/to/openSUSE_13.1.iso" }
  let(:image_two) { "/path/to/openSUSE_12.3.iso" }

  after(:each) do
    # Clear list of started systems, otherwise the helper will try to shutdown
    # boxes which weren't actually started because those calls are stubbed in
    # the tests.
    @pennyworth_systems = []
  end

  describe "#start_system" do
    it "raises an exception if no valid image parameter is given" do
      expect {
        start_system(foo: "bar")
      }.to raise_error
    end

    it "starts the given vagrant boxes" do
      runner_one = double
      expect(Pennyworth::VagrantRunner).to receive(:new).with(system_one, anything, anything) { runner_one }
      expect(runner_one).to receive(:start)
      runner_two = double
      expect(Pennyworth::VagrantRunner).to receive(:new).with(system_two, anything, anything) { runner_two }
      expect(runner_two).to receive(:start)
      expect(Pennyworth::SshKeysImporter).to receive(:import).twice

      expect(self.class).to receive(:after).twice
      start_system(box: system_one)
      start_system(box: system_two)
    end

    it "starts the given images" do
      runner_one = double
      expect(Pennyworth::ImageRunner).to receive(:new).with(image_one, anything) { runner_one }
      expect(runner_one).to receive(:start)
      runner_two = double
      expect(Pennyworth::ImageRunner).to receive(:new).with(image_two, anything) { runner_two }
      expect(runner_two).to receive(:start)
      expect(Pennyworth::SshKeysImporter).to receive(:import).twice

      expect(self.class).to receive(:after).twice
      start_system(image: image_one)
      start_system(image: image_two)
    end

    it "starts the given host" do
      runner = double
      expect(runner).to receive(:start)
      expect(Pennyworth::HostRunner).to receive(:new).
        with("test_host", instance_of(Pennyworth::HostConfig), "root").
        and_return(runner)
      expect(Pennyworth::SshKeysImporter).to_not receive(:import)

      expect(self.class).to receive(:after).once
      start_system(host: "test_host")
    end

    it "forwards the username and password options" do
      runner_one = double
      expect(Pennyworth::VagrantRunner).to receive(:new).with(system_one, anything, "machinery") { runner_one }
      expect(runner_one).to receive(:start)
      expect(Pennyworth::SshKeysImporter).to receive(:import).with(anything, "machinery", "linux")

      start_system(box: system_one, username: "machinery", password: "linux")
    end

    it "uses LocalRunner for local tests" do
      opts = {
        env: { "FOO" => "BAR" }
      }
      expect(Pennyworth::LocalRunner).to receive(:new).with(opts).and_call_original
      expect(Pennyworth::SshKeysImporter).to_not receive(:import)

      start_system(opts.merge(local: true))
    end

    context "when 'stop' option is set to false" do
      it "does not stop the machine after the tests" do
        runner = double
        expect(runner).to receive(:start)
        expect(Pennyworth::VagrantRunner).to receive(:new).and_return(runner)
        expect(Pennyworth::SshKeysImporter).to receive(:import)

        expect(self.class).to_not receive(:after)
        start_system(box: system_one, stop: false)
      end
    end
  end
end
