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

require_relative "lib/pennyworth/constants"
require_relative "lib/pennyworth/version"
require_relative "tools/release"
require "rspec/core/rake_task"
require "cheetah"
require "packaging"

RSpec::Core::RakeTask.new

namespace :man_pages do
  task :build do
    puts "  Building man pages"
    system "ronn man/*.md"
  end
end

namespace :gem do
  task :build => ["man_pages:build"] do
    system "gem build pennyworth.gemspec"
  end
end

desc "Release a new version ('type' is either 'major', 'minor 'or 'patch')"
task :release, [:type] do |task, args|
  unless ["major", "minor", "patch"].include?(args[:type])
    puts "Please specify a valid release type (major, minor or patch)."
    exit 1
  end

  new_version = Release.generate_release_version(args[:type])
  release = Release.new(version: new_version)

  # Check syntax, git and CI state
  Rake::Task['check:committed'].invoke
  Rake::Task['check:syntax'].invoke
  release.check

  release.publish
end
