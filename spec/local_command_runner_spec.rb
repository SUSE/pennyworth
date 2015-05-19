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

describe Pennyworth::LocalCommandRunner do
  use_given_filesystem
  let(:command_runner) { Pennyworth::LocalCommandRunner.new }

  it_behaves_like "a command runner"

  describe "#run" do
    it "executes commands via Cheetah" do
      expect(Cheetah).to receive(:run).with("bash", "-c", "foo bar", stdout: :capture)

      command_runner.run("foo bar", stdout: :capture)
    end

    it "prepends the env variable to the command" do
      runner = Pennyworth::LocalCommandRunner.new(
        env: {
          "MACHINERY_DIR" => "/tmp"
        }
      )
      expect(runner).to receive(:with_env).with("MACHINERY_DIR" => "/tmp").and_call_original
      expect(Cheetah).to receive(:run).with("bash", "-c", "foo bar", stdout: :capture)

      runner.run("foo bar", stdout: :capture)
    end
  end

  describe "#extract_file" do
    before(:each) do
      @source_file = given_dummy_file "example.file"
      @target = given_directory
      @expected_file = File.join(@target, "example.file")
    end

    it "extracts the file" do
      command_runner.extract_file(@source_file, @target)

      expect(File.exists?(File.join(@target, "example.file"))).to be(true)
    end
  end

  describe "#inject_file" do
    before(:each) do
      @source_file = given_dummy_file "example.file"
      @target = given_directory
      @expected_file = File.join(@target, "example.file")
    end

    it "injects the file" do
      command_runner.inject_file(@source_file, @target)
      expect(File.exists?(File.join(@target, "example.file"))).to be(true)
    end

    it "copies the file and sets the owner" do
      expect(FileUtils).to receive(:chown).with("tux", nil, @expected_file)

      command_runner.inject_file(@source_file, @target, owner: "tux")
    end

    it "copies the file and sets the group" do
      expect(FileUtils).to receive(:chown).with(nil, "tux", @expected_file)

      command_runner.inject_file(@source_file, @target, group: "tux")
    end

    it "copies the file and sets the mode" do
      expect(FileUtils).to receive(:chmod).with("600", @expected_file)

      command_runner.inject_file(@source_file, @target, mode: "600")
    end
  end

  describe "#inject_directory" do
    before(:each) do
      @source_dir = given_directory do
        @source_file = given_dummy_file "example.file"
      end

      @target = given_directory
      @expected_dir = File.join(@target, File.basename(@source_dir))
      @expected_file = File.join(@target, File.basename(@source_dir), "example.file")
    end

    it "injects the directory" do
      command_runner.inject_directory(@source_dir, @target)

      expect(Dir.exists?(@expected_dir)).to be(true)
      expect(File.exists?(@expected_file)).to be(true)
    end

    it "copies the directory and sets the user and group" do
      expect(FileUtils).to receive(:chown_R).with("user", "group", @target)

      command_runner.inject_directory(@source_dir, @target, owner: "user", group: "group")
    end
  end
end
