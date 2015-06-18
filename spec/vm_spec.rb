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

require "pennyworth/spec"

describe Pennyworth::VM do
  let(:command_runner) { double(:run) }
  let(:runner) { double(command_runner: command_runner) }
  subject { Pennyworth::VM.new(runner) }

  describe "#run_command" do
    it "lets the CommandRunner run the command" do
      expect(command_runner).to receive(:run)

      subject.run_command("ls")
    end

    it "captures the stderr by default" do
      expect(command_runner).to receive(:run) do |command, opts|
        expect(command).to eq("foo")
        expect(opts[:stderr]).to be_a(StringIO)
      end

      subject.run_command("foo")
    end

    it "allows for setting a custom stderr behavior" do
      expect(command_runner).to receive(:run).with("foo", stderr: :capture)

      subject.run_command("foo", stderr: :capture)
    end

    context "with stderr output" do
      before(:each) do
        expect(command_runner).to receive(:run) do |_command, opts|
          expect(opts[:stderr]).to be_a(StringIO)

          opts[:stderr].puts "some stderr output!"
        end
      end

      it "raises an error by default" do
        expect {
          subject.run_command("foo")
        }.to raise_error(Pennyworth::StderrOutputReceived)
      end

      it "does not raise an error if 'fail_on_stderr_output' is set to false" do
        expect {
          subject.run_command("foo", fail_on_stderr_output: false)
        }.to_not raise_error
      end

      it "does not raise an error if a custom stderr option was set" do
        io = StringIO.new
        expect {
          subject.run_command("foo", stderr: io)
        }.to_not raise_error
      end
    end
  end

  describe "#extract_file" do
    it "lets the CommandRunner extract the file" do
      expect(command_runner).to receive(:extract_file).with("/etc/hosts", "/tmp")

      subject.extract_file("/etc/hosts", "/tmp")
    end
  end

  describe "#inject_file" do
    it "lets the CommandRunner inject the file" do
      expect(command_runner).to receive(:inject_file).with("/tmp/hosts", "/etc", {})

      subject.inject_file("/tmp/hosts", "/etc")
    end
  end

  describe "#inject_directory" do
    it "lets the CommandRunner inject the file" do
      expect(command_runner).to receive(:inject_directory).with("/tmp/hosts", "/etc", {})

      subject.inject_directory("/tmp/hosts", "/etc")
    end
  end
end
