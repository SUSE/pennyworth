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

shared_examples "a runner" do
  it "has a start method" do
    expect(runner).to respond_to(:start)
  end

  it "has a stop method" do
    expect(runner).to respond_to(:stop)
  end

  it "has a command_runner method" do
    expect(runner).to respond_to(:command_runner)
  end

  it "has a running method" do
    expect(runner).to respond_to(:running)
  end
end
