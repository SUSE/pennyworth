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
  describe "#run_command" do
    it "lets a RemoteCommandRunner run the command" do
      runner = double
      expect(RemoteCommandRunner).to receive(:new).with("1.2.3.4").and_return(runner)
      expect(runner).to receive(:run)

      system = VM.new(nil)
      system.ip = "1.2.3.4"
      system.run_command("ls")
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
      expect(Cheetah).to receive(:run) { |*args| expect(args.join(" ")).to match(/chown.*tux/) }

      system = VM.new(nil)
      system.ip = "1.2.3.4"
      system.inject_file("/tmp/hosts", "/etc", owner: "tux")
    end

    it "copies the file and sets the group" do
      expect(Cheetah).to receive(:run) { |*args| expect(args).to include(/scp/) }
      expect(Cheetah).to receive(:run) { |*args| expect(args.join(" ")).to match(/chown.*:tux/) }

      system = VM.new(nil)
      system.ip = "1.2.3.4"
      system.inject_file("/tmp/hosts", "/etc", group: "tux")
    end

    it "copies the file and sets the mode" do
      expect(Cheetah).to receive(:run) { |*args| expect(args).to include(/scp/) }
      expect(Cheetah).to receive(:run) { |*args| expect(args.join(" ")).to include("chmod 600") }

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
      expect(Cheetah).to receive(:run) { |*args| expect(args.join(" ")).to include("chown -R user:group") }

      system = VM.new(nil)
      system.ip = "1.2.3.4"
      system.inject_directory("/tmp/hosts", "/etc", owner: "user", group: "group")
    end
  end

end
