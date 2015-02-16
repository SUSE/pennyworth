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

describe LocalCommandRunner do
  describe "#run" do
    it "executes commands via Cheetah" do
      expect(Cheetah).to receive(:run).with("foo", "bar", stdout: :capture)

      subject.run("foo", "bar", stdout: :capture)
    end

    it "prepends the env variable to the command" do
      runner = LocalCommandRunner.new({
        env: { "MACHINERY_DIR" => "/tmp" }
      })
      expect(runner).to receive(:with_env).with("MACHINERY_DIR" => "/tmp").and_call_original
      expect(Cheetah).to receive(:run).with("foo", "bar", stdout: :capture)

      runner.run("foo", "bar", stdout: :capture)
    end

    it "replaces commands according to the command map" do
      runner = LocalCommandRunner.new({
        command_map: { "machinery" => "/my/local/machinery" }
      })
      expect(Cheetah).to receive(:run).with("/my/local/machinery")

      runner.run("machinery")
    end

    it "replaces commands according to the command map when sudo is used" do
      runner = LocalCommandRunner.new({
        command_map: { "machinery" => "/my/local/machinery" }
      })
      expect(Cheetah).to receive(:run).with("sudo", "/my/local/machinery")

      runner.run("sudo", "machinery")
    end
  end
end
