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

class ListCommand < BaseCommand
  def execute
    if @kiwi_dir
      puts "Vagrant box definitions managed by pennyworth:"
      local_base_images.each do |b|
        puts "  #{b}"
      end
      puts
    end

    puts "Available Vagrant boxes:"
    VagrantCommand.new.list.each do |box|
      puts "  #{box}"
    end
    puts

    puts "Availabe VMs:"
    VagrantCommand.new.status.each do |vm|
      puts "  #{vm}"
    end
  end
end
