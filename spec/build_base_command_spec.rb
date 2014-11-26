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

require "spec_helper.rb"

describe BuildBaseCommand do

  let(:tmp_dir) { "/tmp/kiwi-vagrant-build-environment" }
  let(:expected_content) {
    <<-EOT
---
base_opensuse13.1_kvm:
  sources:
    config.sh: 00cd92ac20df539d7d6f7930a339c622
    config.xml: 43dd3b9cd11bc9d882f8f82ac108b74a
    root/home/vagrant/.ssh/authorized_keys: b440b5086dd12c3fd8abb762476b9f40
  target: 115469c104dcc69455f321eb086ffb11
base_opensuse12.3_kvm:
  sources:
    config.sh: c6640ba00ab345b7491b836d517a637b
    config.xml: a3d3de67d84f7792bf2755f7a3ae4e3f
    root/home/vagrant/.ssh/authorized_keys: b440b5086dd12c3fd8abb762476b9f40
  target: e4e743b5340686d8488dbce54b5644d8
EOT
  }

  context "with non-existing box state file" do
    before(:each) do
      Cli.settings = Settings.new
      @kiwi_dir = File.join(test_data_dir, "kiwi")
      @cmd = BuildBaseCommand.new(@kiwi_dir)
    end

    it "reads box sources state of one box" do
      source_state = @cmd.read_box_sources_state("base_opensuse12.3_kvm")

      expect(source_state.count).to eq 3
      expect(source_state["config.sh"]).to eq "c6640ba00ab345b7491b836d517a637b"
    end

    it "reads box target state of one box" do
      target_state = @cmd.read_box_target_state("base_opensuse13.1_kvm")

      expect(target_state).to eq "115469c104dcc69455f321eb086ffb11"
    end

    it "writes box state file" do
      box_state_file = File.join(@kiwi_dir, "box_state.yaml")

      box_state = {}
      [ "base_opensuse13.1_kvm", "base_opensuse12.3_kvm" ].each do |box|
        box_state[box] = {}
        box_state[box]["sources"] = @cmd.read_box_sources_state(box)
        target_state = @cmd.read_box_target_state(box)
        if target_state
          box_state[box]["target"] = target_state
        end
      end

      FileUtils.rm(box_state_file) if File.exist?(box_state_file)

      @cmd.write_box_state_file(box_state)

      expect(File.read(box_state_file)).to eq expected_content

      FileUtils.rm(box_state_file) if File.exist?(box_state_file)
    end

    it "doesn't fail reading box state file" do
      box_state = @cmd.read_local_box_state_file

      expect(box_state).to eq({})
    end

    it "preserves the state data of other boxes on build-base" do
      # Don't actually build
      allow(@cmd).to receive(:base_image_create)
      allow(@cmd).to receive(:base_image_export)
      allow(@cmd).to receive(:base_image_cleanup_build)

      allow(@cmd).to receive(:log) # Don't print to stdout

      @cmd.execute(tmp_dir, "base_opensuse13.1_kvm")
      @cmd.execute(tmp_dir, "base_opensuse12.3_kvm")

      box_state_file = File.join(@kiwi_dir, "box_state.yaml")

      expect(File.read(box_state_file)).to eq expected_content

      FileUtils.rm(box_state_file) if File.exist?(box_state_file)
    end
  end

  context "with existing box state file" do
    before(:each) do
      Cli.settings = Settings.new
      @kiwi_dir = File.join(test_data_dir, "kiwi2")
      @cmd = BuildBaseCommand.new(@kiwi_dir)
    end

    it "reads box state file" do
      box_state = @cmd.read_local_box_state_file

      expect(box_state["base_opensuse12.3_kvm"]["sources"]["config.sh"]).to eq(
        "c6640ba00ab345b7491b836d517a637b")
      expect(box_state["base_opensuse13.1_kvm"]["target"]).to eq(
        "115469c104dcc69455f321eb086ffb11")
    end

    it "rebuilds box with changed sources" do
      allow(@cmd).to receive(:log) # Don't print to stdout
      allow(@cmd).to receive(:write_box_state_file) # Don't actually write data

      expect(@cmd).to receive(:base_image_create)
      expect(@cmd).to receive(:base_image_export)
      expect(@cmd).to receive(:base_image_cleanup_build)
      @cmd.execute(tmp_dir, "base_opensuse13.1_kvm")
    end

    it "doesn't rebuild box with unchanged sources" do
      allow(@cmd).to receive(:log) # Don't print to stdout
      allow(@cmd).to receive(:write_box_state_file) # Don't actually write data

      expect(@cmd).to_not receive(:base_image_create)
      @cmd.execute(tmp_dir, "base_opensuse12.3_kvm")
    end
  end

end
