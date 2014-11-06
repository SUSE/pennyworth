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

require 'spec_helper'

describe VagrantRunner do
  describe "#start" do
    it "returns the IP address of the started system" do
      runner = VagrantRunner.new("foo", RSpec.configuration.vagrant_dir, "libvirt")

      allow_any_instance_of(Vagrant).to receive(:run)
      expect_any_instance_of(Vagrant).to receive(:ssh_config).with("foo") {
        {
          "foo" => {
            "HostName" => "1.2.3.4"
          }
        }
      }

      expect(runner.start).to eq("1.2.3.4")
    end
  end
end
