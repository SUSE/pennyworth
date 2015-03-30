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

require "spec"

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
      expect(VagrantRunner).to receive(:new).with(system_one, anything) { runner_one }
      expect(runner_one).to receive(:start)
      runner_two = double
      expect(VagrantRunner).to receive(:new).with(system_two, anything) { runner_two }
      expect(runner_two).to receive(:start)
      expect(SshKeysImporter).to receive(:import).twice

      expect(self.class).to receive(:after).twice
      start_system(box: system_one)
      start_system(box: system_two)
    end

    it "starts the given images" do
      runner_one = double
      expect(ImageRunner).to receive(:new).with(image_one) { runner_one }
      expect(runner_one).to receive(:start)
      runner_two = double
      expect(ImageRunner).to receive(:new).with(image_two) { runner_two }
      expect(runner_two).to receive(:start)
      expect(SshKeysImporter).to receive(:import).twice

      expect(self.class).to receive(:after).twice
      start_system(image: image_one)
      start_system(image: image_two)
    end

    it "starts the given host" do
      runner = double
      expect(runner).to receive(:start)
      expect(HostRunner).to receive(:new).
        with("test_host", instance_of(HostConfig)).
        and_return(runner)
      expect(SshKeysImporter).to_not receive(:import)

      expect(self.class).to receive(:after).once
      start_system(host: "test_host")
    end

    it "uses LocalRunner for local tests" do
      opts = {
        env: { "FOO" => "BAR" }
      }
      expect(LocalRunner).to receive(:new).with(opts).and_call_original
      expect(SshKeysImporter).to_not receive(:import)

      start_system(opts.merge(local: true))
    end
  end
end
