# -*- encoding: utf-8 -*-

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

require File.expand_path("../lib/pennyworth/version", __FILE__)

Gem::Specification.new do |s|
  s.name        = "pennyworth-tool"
  s.version     = Pennyworth::VERSION
  s.license     = 'GPL-3.0'
  s.platform    = Gem::Platform::RUBY
  s.authors     = ['SUSE']
  s.email       = ['machinery@lists.suse.com']
  s.homepage    = "https://github.com/SUSE/pennyworth"
  s.summary     = "A tool for running integration tests inside a network of virtual machines"
  s.description = <<-EOT.split("\n").map(&:strip).join(" ")
    Pennyworth is a tool for running integration tests inside a network of
    virtual machines. It allows to define virtual machines, build them as
    Vagrant boxes and run them using libvirt and kvm in coordinated fashion in
    order to run the tests. These tests can be written in any
    language/framework, but the preferred combination is Ruby/RSpec, for which
    helpers are provided.
  EOT

  s.required_ruby_version = ">= 2.0.0"
  s.required_rubygems_version = ">= 1.3.6"
  s.rubyforge_project         = "pennyworth"

  s.add_dependency "gli", "~> 2.11.0"
  s.add_dependency "cheetah"
  s.add_dependency "colorize"
  s.add_dependency "nokogiri"
  s.add_dependency "ruby-libvirt", "~> 0.4.0"

  s.files        = `git ls-files`.split("\n")
  s.executables  = `git ls-files`.split("\n").map{|f| f =~ /^bin\/(.*)/ ? $1 : nil}.compact
  s.require_path = 'lib'

  s.files += Dir['man/*.?']            # UNIX man pages
  s.files += Dir['man/*.{html,css,js}']  # HTML man pages
  s.add_development_dependency 'ronn', '>=0.7.3'
  s.add_development_dependency 'rake'
end
