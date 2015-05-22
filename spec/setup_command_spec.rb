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
require_relative "../lib/pennyworth/commands/setup_command.rb"

describe Pennyworth::SetupCommand do
  let(:setup_command) { Pennyworth::SetupCommand.new }

  describe "#show_warning_for_unsupported_platforms" do
    it "shows warning if current distribution is openSUSE 13.1" do
      openSUSE131_release_file = <<-EOF
NAME=openSUSE
VERSION="13.1 (Bottle)"
VERSION_ID="13.1"
EOF
      expect(setup_command).to receive(:read_os_release_file).and_return(openSUSE131_release_file)
      expect(setup_command).to receive(:log).with(
        "Warning: Pennyworth is not tested upstream on this platform. " \
        "Use at your own risk."
      )
      setup_command.show_warning_for_unsupported_platforms
    end

    it "shows no warning for supported SLES 12 distribution" do
      sles12_release_file = <<-EOF
NAME="SLES"
VERSION="12"
VERSION_ID="12"
PRETTY_NAME="SUSE Linux Enterprise Server 12"
EOF
      expect(setup_command).to receive(:read_os_release_file).and_return(sles12_release_file)
      expect(setup_command).not_to receive(:log)
      setup_command.show_warning_for_unsupported_platforms
    end
  end
end
