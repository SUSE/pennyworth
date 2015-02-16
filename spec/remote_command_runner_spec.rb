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

describe RemoteCommandRunner do
  let(:ssh_output) { "-rw-r--r-- 1 root root 642 Sep 27 22:06 /etc/hosts" }
  let(:command_runner) { RemoteCommandRunner.new("1.2.3.4") }

  it_behaves_like "a command runner"

  describe "#run" do
    it "calls ssh and returns the command's standard output" do
      expect(Cheetah).to receive(:run).
        and_return(ssh_output)

      output = command_runner.run("ls", "-l", "/etc/hosts", stdout: :capture)

      expect(output).to eq (ssh_output)
    end

    it "executes commands as given user" do
      expect(Cheetah).to receive(:run).
        with(
        "ssh", "-o", "UserKnownHostsFile=/dev/null", "-o", "StrictHostKeyChecking=no",
        "root@1.2.3.4", "LC_ALL=C", "su", "-l", "vagrant", "-c", "ls", "-l", "/etc/hosts",
        stdout: :capture).
        and_return(ssh_output)

      output = command_runner.run("ls", "-l", "/etc/hosts", as: "vagrant", stdout: :capture)

      expect(output).to eq (ssh_output)
    end

    it "raises ExecutionFailed in case of errors" do
      expect(Cheetah).to receive(:run).and_raise(Cheetah::ExecutionFailed.new(nil, nil, nil, nil))

      expect {
        command_runner.run("foo")
      }.to raise_error(ExecutionFailed)
    end
  end

  describe "#extract_file" do
    it "calls scp with source and destination as arguments" do
      expect(Cheetah).to receive(:run)

      command_runner.extract_file("/etc/hosts", "/tmp")
    end
  end

  describe "#inject_file" do
    it "calls scp with source and destination as arguments" do
      expect(Cheetah).to receive(:run)

      command_runner.inject_file("/tmp/hosts", "/etc")
    end

    it "copies the file and sets the owner" do
      expect(Cheetah).to receive(:run) { |*args| expect(args).to include(/scp/) }
      expect(Cheetah).to receive(:run) { |*args| expect(args.join(" ")).to match(/chown.*tux/) }

      command_runner.inject_file("/tmp/hosts", "/etc", owner: "tux")
    end

    it "copies the file and sets the group" do
      expect(Cheetah).to receive(:run) { |*args| expect(args).to include(/scp/) }
      expect(Cheetah).to receive(:run) { |*args| expect(args.join(" ")).to match(/chown.*:tux/) }

      command_runner.inject_file("/tmp/hosts", "/etc", group: "tux")
    end

    it "copies the file and sets the mode" do
      expect(Cheetah).to receive(:run) { |*args| expect(args).to include(/scp/) }
      expect(command_runner).to receive(:run) do |*args|
        expect(args.join(" ")).to include("chmod 600")
      end

      command_runner.inject_file("/tmp/hosts", "/etc", mode: "600")
    end
  end

  describe "#inject_directory" do
    it "calls scp with source and destination as arguments" do
      expect(Cheetah).to receive(:run) { |*args| expect(args).to include(/mkdir -p/) }
      expect(Cheetah).to receive(:run) { |*args| expect(args).to include(/scp/) }

      command_runner.inject_directory("/tmp/hosts", "/etc")
    end

    it "copies the directory and sets the user and group" do
      expect(Cheetah).to receive(:run) { |*args| expect(args).to include(/mkdir -p/) }
      expect(Cheetah).to receive(:run) { |*args| expect(args).to include(/scp/) }
      expect(Cheetah).to receive(:run) do |*args|
        expect(args.join(" ")).to include("chown -R user:group")
      end

      command_runner.inject_directory("/tmp/hosts", "/etc", owner: "user", group: "group")
    end
  end
end
