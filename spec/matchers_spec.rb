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
require "pennyworth/vm"

describe "VM matchers" do
  describe "have_exit_code" do
    let(:result) { command_result("", "", 0) }

    it "passes" do
      expect(result).to have_exit_code(0)
    end

    it "fails" do
      expect {
        expect(result).to have_exit_code(1)
      }.to raise_error(/to have exit code 1/)
    end
  end

  describe "succeed" do
    it "passes" do
      expect(command_result("", "", 0)).to succeed
    end

    it "fails on exit code != 0" do
      expect {
        expect(command_result("", "", 1)).to succeed
      }.to raise_error(/Expected.*the command.*but it returned with exit code 1/m)
    end

    context "with stderr output" do
      let(:result) { command_result("", "foo", 0) }

      it "fails" do
        expect {
          expect(result).to succeed
        }.to raise_error(/Expected.*the command.*but it had stderr output/m)
      end

      it "passes if '.with_stderr' was used" do
        expect(result).to succeed.with_stderr
      end
    end
  end

  describe "fail" do
    it "passes" do
      expect(command_result("", "", 1)).to fail
    end

    it "fails" do
      expect {
        expect(command_result("", "", 0)).to fail
      }.to raise_error(/but it succeeded/)
    end

    context ".with_exit_code" do
      it "passes on exit code" do
        expect(command_result("", "", 3)).to fail.with_exit_code(3)
      end

      it "fails on exit code" do
        expect {
          expect(command_result("", "", 3)).to fail.with_exit_code(2)
        }.to raise_error(/Expected.*the command.*but it exited with 3/m)
      end
    end
  end

  describe "have_stderr" do
    let(:result) { command_result("", "foo", 1) }

    context "with a Regexp" do
      it "passes" do
        expect(result).to have_stderr(/f.o/)
      end

      it "fails" do
        expect {
          expect(result).to have_stderr(/g.o/)
        }.to raise_error(/to match \/g.o\//)
      end
    end

    context "with a String" do
      it "passes" do
        expect(result).to have_stderr("foo")
      end

      it "fails" do
        expect {
          expect(result).to have_stderr("bar")
        }.to raise_error(/to be 'bar'/)
      end
    end
  end

  describe "include_stderr" do
    let(:result) { command_result("", "foo", 1) }

    it "passes" do
      expect(result).to include_stderr("fo")
    end

    it "fails" do
      expect {
        expect(result).to include_stderr("ba")
      }.to raise_error(/to include 'ba'/)
    end
  end

  describe "have_stdout" do
    let(:result) { command_result("foo", "", 0) }

    context "with a Regexp" do
      it "passes" do
        expect(result).to have_stdout(/f.o/)
      end

      it "fails" do
        expect {
          expect(result).to have_stdout(/g.o/)
        }.to raise_error(/to match \/g.o\//)
      end
    end

    context "with a String" do
      it "passes" do
        expect(result).to have_stdout("foo")
      end

      it "fails" do
        expect {
          expect(result).to have_stdout("bar")
        }.to raise_error(/to be 'bar'/)
      end
    end
  end

  describe "include_stdout" do
    let(:result) { command_result("foo", "", 0) }

    it "passes" do
      expect(result).to include_stdout("fo")
    end

    it "fails" do
      expect {
        expect(result).to include_stdout("ba")
      }.to raise_error(/to include 'ba'/)
    end
  end

  def command_result(stdout, stderr, exit_code)
    res = Pennyworth::VM::CommandResult.new
    res.cmd = "the command"
    res.stdout = stdout
    res.stderr = stderr
    res.exit_code = exit_code

    res
  end
end
