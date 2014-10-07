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

describe VagrantCommand do

  it "parses output of `vagrant status`" do
    status_output = <<-EOT
Current machine states:

opensuse123               running (libvirt)
opensuse131               not created (libvirt)
master                    not created (libvirt)

This environment represents multiple VMs. The VMs are all listed
above with their current state. For more information about a specific
VM, run `vagrant status NAME`.
EOT
    vms = VagrantCommand.parse_status status_output
    expect( vms ).to eq [ "opensuse123 (running)","opensuse131","master" ]
  end

  describe ".setup_environment" do
    it "creates <dir> and calls vagrant init if there is no Vagrantfile" do
      Dir.mktmpdir("vagrant_command_test") do |tmp_dir|
        dir = File.join(tmp_dir, "pennyworth")
        expect(Dir.exists?(dir)).to be(false)
        expect(Vagrant).to receive(:new).with(dir).and_call_original
        expect_any_instance_of(Vagrant).to receive(:run).with("init")

        VagrantCommand.setup_environment(dir)
        expect(Dir.exists?(dir)).to be(true)
      end
    end
  end
end
