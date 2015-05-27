# encoding:utf-8

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

require_relative "release_checks"

class Release
  include ReleaseChecks

  def initialize(opts = {})
    @options = {
      version:      generate_development_version
    }.merge(opts)
    @release_version = @options[:version]
    @tag             = "v#{@release_version}"
    @release_time    = Time.now.strftime('%a %b %d %H:%M:%S %Z %Y')
    @mail            = Cheetah.run(["git", "config", "user.email"], :stdout => :capture).chomp
    @gemspec         = Gem::Specification.load("pennyworth.gemspec")
  end

  # Commit version changes, tag release and push changes upstream.
  def publish
    set_version
    finalize_news_file

    commit
  end

  # Calculates the next version number according to the release type (:major, :minor or :patch)
  def self.generate_release_version(release_type)
    current_version = Pennyworth::VERSION
    major, minor, patch = current_version.scan(/(\d+)\.(\d+)\.(\d+)/).first.map(&:to_i)

    case release_type
    when "patch"
      patch += 1
    when "minor"
      patch = 0
      minor += 1
    when "major"
      patch = 0
      minor = 0
      major += 1
    end

    "#{major}.#{minor}.#{patch}"
  end

  private

  def set_version
    Dir.chdir(Pennyworth::ROOT) do
      Cheetah.run "sed", "-i", "s/VERSION.*=.*/VERSION = \"#{@release_version}\"/", "lib/pennyworth/version.rb"
    end
  end

  def finalize_news_file
    file = File.join(Pennyworth::ROOT, "NEWS")
    content = File.read(file)
    # All changes for the next release are directly added below the headline
    # by the developers without adding a version line.
    # Since the version line is automatically added during release by this
    # method we can check for new bullet points since the last release.
    if content.scan(/# Pennyworth .*$\n+## Version /).empty?
      content = content.sub(/\n+/, "\n\n\n## Version #{@release_version} - #{@release_time} - #{@mail}\n\n")
      File.write(file, content)
    end
  end

  def commit
    Cheetah.run "git", "commit", "-a", "-m", "package #{@release_version}"
    Cheetah.run "git", "tag", "-a", @tag, "-m", "Tag version #{@release_version}"
    Cheetah.run "git", "push"
    Cheetah.run "git", "push", "--tags"
  end

  def generate_development_version
    # The development version RPMs have the following version number scheme:
    # <base version>.<timestamp><os>git<short git hash>
    timestamp = Time.now.strftime("%Y%m%dT%H%M%SZ")
    commit_id = Cheetah.run("git", "rev-parse", "--short", "HEAD", :stdout => :capture).chomp

    "#{Pennyworth::VERSION}.#{timestamp}git#{commit_id}"
  end

end
