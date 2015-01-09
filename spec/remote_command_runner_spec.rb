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

describe RemoteCommandRunner do
  let(:ssh_output) { "-rw-r--r-- 1 root root 642 Sep 27 22:06 /etc/hosts" }
  subject { RemoteCommandRunner.new("1.2.3.4") }

  describe "#run" do
    it "calls ssh and returns the command's standard output" do
      expect(Cheetah).to receive(:run).
        and_return(ssh_output)

      output = subject.run("ls", "-l", "/etc/hosts", {:stdout=>:capture})

      expect(output).to eq (ssh_output)
    end

    it "executes commands as given user" do
      expect(Cheetah).to receive(:run).
        with(
        "ssh", "-o", "UserKnownHostsFile=/dev/null", "-o", "StrictHostKeyChecking=no",
        "root@1.2.3.4", "LC_ALL=C", "su", "-l", "vagrant", "-c", "ls", "-l", "/etc/hosts",
        {:stdout=>:capture}).
        and_return(ssh_output)

      output = subject.run("ls", "-l", "/etc/hosts", {as: "vagrant", stdout: :capture})

      expect(output).to eq (ssh_output)
    end

    it "raises ExecutionFailed in case of errors" do
      expect(Cheetah).to receive(:run).and_raise(Cheetah::ExecutionFailed.new(nil, nil, nil, nil))

      expect {
        subject.run("foo")
      }.to raise_error(ExecutionFailed)
    end
  end
end
