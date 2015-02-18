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

describe LocalRunner do
  let(:runner) {
    LocalRunner.new
  }

  it_behaves_like "a runner"

  describe "#command_runner" do
    it "returns a LocalCommandRunner" do
      expect(runner.command_runner).to be_a(LocalCommandRunner)
    end

    it "forwards the :env and :command_map options to the LocalCommandRunner" do
      opts = {
        env: { "FOO" => "BAR" },
        command_map: { "foo" => "/bar" }
      }
      expect(LocalCommandRunner).to receive(:new).with(opts)

      LocalRunner.new(opts).command_runner
    end
  end
end
