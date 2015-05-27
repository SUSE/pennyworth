# Copyright (c) 2013-2015 SUSE LLC
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
module ReleaseChecks
  def check
    check_tag
  end

  private

  def fail(msg)
    puts msg
    exit 1
  end

  def check_tag
    Cheetah.run("git", "fetch", "--tags")
    existing_tag = Cheetah.run("git", "tag", "-l", @tag, stdout: :capture)

    fail "Tag #{@tag} already exists. Abort." unless existing_tag.empty?
  end
end
