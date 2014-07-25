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

require 'spec'

describe 'Spec Profiler' do
  it "measures top level items" do
    @measurements = []
    measure("top level item") {}

    expect(@measurements.size).to eq(1)
    expect(@measurements.first[:label]).to eq("top level item")
    expect(@measurements.first[:child_measurements]).to be_empty
  end

  it "measures multiple top level items" do
    @measurements = []
    measure("top level item 1") {}
    measure("top level item 2") {}

    expect(@measurements.size).to eq(2)
    expect(@measurements.first[:label]).to eq("top level item 1")
    expect(@measurements.last[:label]).to eq("top level item 2")
  end

  it "measures nested items" do
    @measurements = []
    measure("top level item") do
      measure("level 1.1") do
        measure("level 2.1") {}
      end
      measure("level 1.2") {}
    end

    expect(@measurements.size).to eq(1)
    expect(@measurements.first[:label]).to eq("top level item")

    children = @measurements.first[:child_measurements]
    expect(children.size).to eq(3)

    expect(children[0][:label]).to eq("level 1.1")
    child_children = children[0][:child_measurements]
    expect(child_children.size).to eq(2)
    expect(child_children[0][:label]).to eq("level 2.1")

    expect(children[1][:child_measurements].size).to eq(0)
    expect(children[2][:label]).to eq("Other")
  end
end
