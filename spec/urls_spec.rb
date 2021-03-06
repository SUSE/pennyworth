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

describe Pennyworth::URLs do
  describe ".join" do
    it "joins parts using slashes" do
      expect(Pennyworth::URLs.join("a", "b", "c")).to eq("a/b/c")
    end

    it "doesn't duplicate slashes before parts containing leading slashes" do
      expect(Pennyworth::URLs.join("a", "/b", "/c")).to eq("a/b/c")
    end

    it "doesn't duplicate slashes after parts containing trailing slashes" do
      expect(Pennyworth::URLs.join("a/", "b/", "c")).to eq("a/b/c")
    end

    it "doesn't duplicate slashes around empty parts" do
      expect(Pennyworth::URLs.join("a", "", "c")).to eq("a/c")
    end

    it "preserves leading slash in the first part" do
      expect(Pennyworth::URLs.join("/a", "b", "c")).to eq("/a/b/c")
    end

    it "preserves trailing slash in the last part" do
      expect(Pennyworth::URLs.join("a", "b", "c/")).to eq("a/b/c/")
    end
  end
end
