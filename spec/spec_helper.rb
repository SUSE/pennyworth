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

require "pennyworth"
require "spec"
require "webmock/rspec"
require "given_filesystem/spec_helpers"

Dir[File.expand_path("../../spec/support/*.rb", __FILE__)].each do |f|
  require f
end

bin_path = File.expand_path( "../../bin/", __FILE__ )

if ENV['PATH'] !~ /#{bin_path}/
  ENV['PATH'] = bin_path + File::PATH_SEPARATOR + ENV['PATH']
end

def test_data_dir
  File.expand_path("../data/", __FILE__)
end

RSpec.configure do |config|
  # In the pennyworth unit tests we don't want to actually run images only test
  # pennyworth and its rspec helper. Thus we have to disable the libvirt setup
  # code in order to not be prompted for the root password each time the tests
  # are run. We also don't want to profile the pennyworth tests, so that is
  # disabled in pennyworth mode as well.
  config.add_setting :pennyworth_mode, default: false
  config.add_setting :vagrant_dir
  config.add_setting :hosts_file

  config.vagrant_dir = File.expand_path("../../vagrant", __FILE__)
  config.hosts_file = File.join(test_data_dir, "hosts.yaml")
  config.pennyworth_mode = true
end
