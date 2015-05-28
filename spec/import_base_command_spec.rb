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

describe Pennyworth::ImportBaseCommand do

  before(:all) do
    Pennyworth::Cli.settings = Pennyworth::Settings.new
    Pennyworth::Cli.settings.definitions_dir = test_data_dir
  end

  before(:each) do
    stub_request(:get, /example.com.*import_state.yaml/).
      with(headers: {'Accept'=>'*/*', 'User-Agent'=>'Ruby'}).
      to_return(status: 200, body: File.read(File.join(test_data_dir,
        "/boxes5/import_state.yaml")), headers: {})
  end

  context "without box state file" do
    before(:each) do
      @boxes_dir = File.join(test_data_dir, "boxes")
      @cmd = Pennyworth::ImportBaseCommand.new(@boxes_dir, "http://example.com/pennyworth/")
      allow(Pennyworth::Libvirt).to receive(:ensure_libvirt_env_started)
      allow(@cmd).to receive(:log)
      allow(@cmd).to receive(:write_import_state_file) # Don't write state
    end

    it "imports a local box" do
      expect(@cmd).to receive(:base_image_clean).with("base_opensuse12.3_kvm")
      expect_any_instance_of(Pennyworth::Vagrant).to receive(:run).with("box", "add",
        "base_opensuse12.3_kvm", "#{@boxes_dir}/base_opensuse12.3_kvm.box",
        "--force")

      @cmd.execute("base_opensuse12.3_kvm", :local => true)
    end

    it "imports a remote box" do
      allow(@cmd).to receive(:fetch_remote_box_state_file)

      expect(@cmd).to receive(:base_image_clean).with("base_opensuse13.1_kvm")
      expect_any_instance_of(Pennyworth::Vagrant).to receive(:run).with("box", "add",
        "base_opensuse13.1_kvm",
        "http://example.com/pennyworth/base_opensuse13.1_kvm.box", "--force")

      @cmd.execute("base_opensuse13.1_kvm")
    end

    context "url checks" do
      before(:each) do
        @box_state_get = stub_request(:get, /example.com\/pennyworth\/box_state.yaml/)
      end

      it "fetches the box state file from an url with a trailing slash" do
        cmd = Pennyworth::ImportBaseCommand.new(@boxes_dir, "http://example.com/pennyworth/")
        cmd.read_remote_box_state_file()

        assert_requested(@box_state_get)
      end

      it "fetches the box state file from an url without a trailing slash" do
        cmd = Pennyworth::ImportBaseCommand.new(@boxes_dir, "http://example.com/pennyworth")
        cmd.read_remote_box_state_file()

        assert_requested(@box_state_get)
      end
    end
  end

  context "with box state file" do
    before(:each) do
      @boxes_dir = File.join(test_data_dir, "boxes2")
      @cmd = Pennyworth::ImportBaseCommand.new(@boxes_dir)
      allow(Pennyworth::Libvirt).to receive(:ensure_libvirt_env_started)
      allow(@cmd).to receive(:log)
      allow(@cmd).to receive(:fetch_remote_box_state_file).and_return(
        File.read(File.join(@boxes_dir, "box_state.yaml")))
    end

    it "writes import state file" do
      allow(@cmd).to receive(:base_image_clean)
      allow(@cmd).to receive(:vagrant)
      allow_any_instance_of(Pennyworth::Vagrant).to receive(:run)

      import_state_file = File.join(@boxes_dir, "import_state.yaml")

      FileUtils.rm(import_state_file) if File.exist?(import_state_file)

      @cmd.execute("base_opensuse13.1_kvm", :local => true)
      @cmd.execute("base_opensuse12.3_kvm", :local => true)

      expected_content = <<-EOT
---
base_opensuse13.1_kvm: 115469c104dcc69455f321eb086ffb11
base_opensuse12.3_kvm: e4e743b5340686d8488dbce54b5644d8
      EOT

      expect(File.read(import_state_file)).to eq expected_content

      FileUtils.rm(import_state_file) if File.exist?(import_state_file)
    end

    it "reads remote box state file" do
      box_state = @cmd.read_remote_box_state_file

      expect(box_state["base_opensuse12.3_kvm"]["sources"]["config.sh"]).to eq(
        "c6640ba00ab345b7491b836d517a637b")
      expect(box_state["base_opensuse13.1_kvm"]["target"]).to eq(
        "115469c104dcc69455f321eb086ffb11")
    end
  end

  context "with box and import state files" do
    before(:each) do
      @boxes_dir = File.join(test_data_dir, "boxes3")
      @cmd = Pennyworth::ImportBaseCommand.new(@boxes_dir, "http://example.com/pennyworth/")
      allow(Pennyworth::Libvirt).to receive(:ensure_libvirt_env_started)
      allow(@cmd).to receive(:log)
      allow(@cmd).to receive(:write_import_state_file) # Don't write state
      allow(@cmd).to receive(:fetch_remote_box_state_file).and_return(
        File.read(File.join(@boxes_dir, "box_state.yaml")))
    end

    it "imports changed local box" do
      expect(@cmd).to receive(:base_image_clean)
      expect_any_instance_of(Pennyworth::Vagrant).to receive(:run)

      @cmd.execute("base_opensuse12.3_kvm", :local => true)
    end

    it "doesn't import unchanged local box" do
      expect(@cmd).to_not receive(:base_image_clean)
      expect_any_instance_of(Pennyworth::Vagrant).to_not receive(:run)

      @cmd.execute("base_opensuse13.1_kvm", :local => true)
    end

    it "imports changed remote box" do
      expect(@cmd).to receive(:base_image_clean)
      expect_any_instance_of(Pennyworth::Vagrant).to receive(:run)

      @cmd.execute("base_opensuse13.2_kvm")
    end

    it "doesn't import unchanged remote box" do
      expect(@cmd).to_not receive(:base_image_clean)
      expect_any_instance_of(Pennyworth::Vagrant).to_not receive(:run)

      @cmd.execute("base_opensuse13.1_kvm")
    end
  end

  context "without box state, but with import state files" do
    before(:each) do
      @boxes_dir = File.join(test_data_dir, "boxes4")
      @cmd = Pennyworth::ImportBaseCommand.new(@boxes_dir)
      allow(Pennyworth::Libvirt).to receive(:ensure_libvirt_env_started)
      allow(@cmd).to receive(:log)
    end

    it "removes imported state after import" do
      expect(@cmd).to receive(:base_image_clean)
      expect_any_instance_of(Pennyworth::Vagrant).to receive(:run)

      import_state = @cmd.read_import_state_file
      expect(import_state["base_opensuse13.1_kvm"]).to eq "115469c104dcc69455f321eb086ffb11"

      expect(@cmd).to receive(:write_import_state_file).with(
        {"base_opensuse13.1_kvm"=>nil, "base_opensuse12.3_kvm"=>"old_hash"}
      )

      @cmd.execute("base_opensuse13.1_kvm", :local => true)
    end
  end
end
