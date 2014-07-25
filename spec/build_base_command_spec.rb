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

  let(:expected_content) {
    <<-EOT
---
base_opensuse13.1_kvm:
  sources:
    autoinst.xml: 009538c8f0325850dfcef70bd7526649
    definition.rb: 1e345450f1d7bef8d68331d95f206fed
    postinstall.sh: e40f4e805919bcfec20f0a12a8a7dcfa
  target: 115469c104dcc69455f321eb086ffb11
base_opensuse12.3_kvm:
  sources:
    autoinst.xml: 9e6d1da4249c57b3750c43e7d9bac51b
    definition.rb: 27b7c76c349165d9160011a68c3e716a
    postinstall.sh: 7272f92d7d15b61c3ab892f16f69449f
  target: e4e743b5340686d8488dbce54b5644d8
EOT
  }

  context "with non-exisiting box state file" do
    before(:each) do
      Cli.settings = Settings.new
      @veewee_dir = File.join(test_data_dir, "veewee")
      @cmd = BuildBaseCommand.new(@veewee_dir)
    end

    it "reads box sources state of one box" do
      source_state = @cmd.read_box_sources_state("base_opensuse12.3_kvm")

      expect(source_state.count).to eq 3
      expect(source_state["autoinst.xml"]).to eq "9e6d1da4249c57b3750c43e7d9bac51b"
    end

    it "reads box target state of one box" do
      target_state = @cmd.read_box_target_state("base_opensuse13.1_kvm")

      expect(target_state).to eq "115469c104dcc69455f321eb086ffb11"
    end

    it "writes box state file" do
      box_state_file = File.join(@veewee_dir, "box_state.yaml")

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
      allow(Pennyworth::Libvirt).to receive(:ensure_libvirt_env_started)

      # Don't actually build
      allow(@cmd).to receive(:base_image_create)
      allow(@cmd).to receive(:base_image_halt)
      allow(@cmd).to receive(:base_image_export)

      allow(@cmd).to receive(:log) # Don't print to stdout

      @cmd.execute("base_opensuse13.1_kvm")
      @cmd.execute("base_opensuse12.3_kvm")

      box_state_file = File.join(@veewee_dir, "box_state.yaml")

      expect(File.read(box_state_file)).to eq expected_content

      FileUtils.rm(box_state_file) if File.exist?(box_state_file)
    end
  end

  context "with existing box state file" do
    before(:each) do
      Cli.settings = Settings.new
      @veewee_dir = File.join(test_data_dir, "veewee2")
      @cmd = BuildBaseCommand.new(@veewee_dir)
    end

    it "reads box state file" do
      box_state = @cmd.read_local_box_state_file

      expect(box_state["base_opensuse12.3_kvm"]["sources"]["autoinst.xml"]).to eq(
        "9e6d1da4249c57b3750c43e7d9bac51b")
      expect(box_state["base_opensuse13.1_kvm"]["target"]).to eq(
        "115469c104dcc69455f321eb086ffb11")
    end

    it "rebuilds box with changed sources" do
      allow(Pennyworth::Libvirt).to receive(:ensure_libvirt_env_started)
      allow(@cmd).to receive(:log) # Don't print to stdout
      allow(@cmd).to receive(:write_box_state_file) # Don't actually write data

      expect(@cmd).to receive(:base_image_create)
      expect(@cmd).to receive(:base_image_halt)
      expect(@cmd).to receive(:base_image_export)
      @cmd.execute("base_opensuse13.1_kvm")
    end

    it "doesn't rebuild box with unchanged sources" do
      allow(Pennyworth::Libvirt).to receive(:ensure_libvirt_env_started)
      allow(@cmd).to receive(:log) # Don't print to stdout
      allow(@cmd).to receive(:write_box_state_file) # Don't actually write data

      expect(@cmd).to_not receive(:base_image_create)
      @cmd.execute("base_opensuse12.3_kvm")
    end
  end

end
