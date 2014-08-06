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

describe VM do
  let(:ssh_output) { "-rw-r--r-- 1 root root 642 Sep 27 22:06 /etc/hosts" }

  describe "#run_command" do
    it "calls ssh and returns the command's standard output" do
      expect(Cheetah).to receive(:run).
        and_return(ssh_output)

      system = VM.new(nil)
      system.ip = "1.2.3.4"
      output = system.run_command("ls", "-l", "/etc/hosts", {:stdout=>:capture})

      expect(output).to eq (ssh_output)
    end

    it "executes commands as given user" do
      expect(Cheetah).to receive(:run).
        with(
          "ssh", "-o", "UserKnownHostsFile=/dev/null", "-o", "StrictHostKeyChecking=no",
          "root@1.2.3.4", "LC_ALL=C", "su", "vagrant", "-c", "ls", "-l", "/etc/hosts",
          {:stdout=>:capture}).
        and_return(ssh_output)

      system = VM.new(nil)
      system.ip = "1.2.3.4"
      output = system.run_command("ls", "-l", "/etc/hosts", {as: "vagrant", stdout: :capture})

      expect(output).to eq (ssh_output)
    end
  end

  describe "#extract_file" do
    it "calls scp with source and destination as arguments" do
      expect(Cheetah).to receive(:run)

      system = VM.new(nil)
      system.ip = "1.2.3.4"
      system.extract_file("/etc/hosts", "/tmp")
    end
  end

  describe "#inject_file" do
    it "calls scp with source and destination as arguments" do
      expect(Cheetah).to receive(:run)

      system = VM.new(nil)
      system.ip = "1.2.3.4"
      system.inject_file("/tmp/hosts", "/etc")
    end

    it "copies the file and sets the owner" do
      expect(Cheetah).to receive(:run) { |*args| expect(args).to include(/scp/) }
      expect(Cheetah).to receive(:run) { |*args| expect(args).to include(/chown.*tux/) }

      system = VM.new(nil)
      system.ip = "1.2.3.4"
      system.inject_file("/tmp/hosts", "/etc", owner: "tux")
    end

    it "copies the file and sets the group" do
      expect(Cheetah).to receive(:run) { |*args| expect(args).to include(/scp/) }
      expect(Cheetah).to receive(:run) { |*args| expect(args).to include(/chown.*:tux/) }

      system = VM.new(nil)
      system.ip = "1.2.3.4"
      system.inject_file("/tmp/hosts", "/etc", group: "tux")
    end

    it "copies the file and sets the mode" do
      expect(Cheetah).to receive(:run) { |*args| expect(args).to include(/scp/) }
      expect(Cheetah).to receive(:run) { |*args| expect(args).to include(/chmod 600/) }

      system = VM.new(nil)
      system.ip = "1.2.3.4"
      system.inject_file("/tmp/hosts", "/etc", mode: "600")
    end
  end

  describe "#inject_directory" do
    it "calls scp with source and destination as arguments" do
      expect(Cheetah).to receive(:run) { |*args| expect(args).to include(/mkdir -p/) }
      expect(Cheetah).to receive(:run) { |*args| expect(args).to include(/scp/) }

      system = VM.new(nil)
      system.ip = "1.2.3.4"
      system.inject_directory("/tmp/hosts", "/etc")
    end

    it "copies the directory and sets the user and group" do
      expect(Cheetah).to receive(:run) { |*args| expect(args).to include(/mkdir -p/) }
      expect(Cheetah).to receive(:run) { |*args| expect(args).to include(/scp/) }
      expect(Cheetah).to receive(:run) { |*args| expect(args).to include(/chown -R user:group/) }

      system = VM.new(nil)
      system.ip = "1.2.3.4"
      system.inject_directory("/tmp/hosts", "/etc", owner: "user", group: "group")
    end
  end

end
