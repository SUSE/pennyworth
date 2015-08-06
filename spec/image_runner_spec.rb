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

describe Pennyworth::ImageRunner do
  let(:libvirt_xml) {
    <<-EOF
      <domain type='kvm' id='52'>
        <devices>
          <interface type='bridge'>
            <mac address='52:54:01:60:3c:95'/>
          </interface>
        </devices>
      </domain>
    EOF
  }
  let(:runner) { Pennyworth::ImageRunner.new("/path/to/image", "root") }

  describe "runner" do
    before(:each) do
      allow(Libvirt).to receive(:open)
    end

    it_behaves_like "a runner"
  end

  describe "#start" do
    it "returns the IP address from the lease file" do
      libvirt = double
      system = double
      expect(::Libvirt).to receive(:open) { libvirt }

      expect(libvirt).to receive(:create_domain_xml)
      expect(libvirt).to receive(:lookup_domain_by_name) { system }

      expect(system).to receive(:xml_desc) { libvirt_xml }

      allow(runner).to receive(:cleanup)
      expect(Cheetah).to receive(:run) do |*cmd|
        expect(cmd.first[0]).to eq("arp")

        "192.168.122.186"
      end

      expect(runner.start).to eq("192.168.122.186")
    end
  end
end
