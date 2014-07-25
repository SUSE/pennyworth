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

class ImageRunner
  DOMAIN_TEMPLATE = File.join(File.dirname(__FILE__) + "/../files/image_test-template.xml")

  attr_accessor :name

  def initialize(image, name = File.basename(image))
    @image = image
    @name = name

    @connection = Libvirt::open("qemu:///system")
  end

  def start
    cleanup()

    start_built_image()
  end

  def stop
    system = @connection.lookup_domain_by_name(@name)
    system.destroy
  end

  private

  def cleanup
    system = @connection.lookup_domain_by_name(@name)
    system.destroy
  rescue
  end

  # Creates a transient kvm domain from the predefined image_test-domain.xml
  # file and returns the ip address for further interaction.
  def start_built_image
    domain_config = File.read(DOMAIN_TEMPLATE)
    domain_config.gsub!("@@image@@", @image)
    domain_config.gsub!("@@name@@", @name)

    @connection.create_domain_xml(domain_config)
    system = @connection.lookup_domain_by_name(@name)

    domain_xml = Nokogiri::XML(system.xml_desc)
    mac = domain_xml.xpath("//domain/devices/interface/mac").attr("address")
    ip_address = nil

    # Loop until the VM has got an IP address we can return
    lease_file = "/var/lib/libvirt/dnsmasq/default.leases"
    300.times do
      match = File.readlines(lease_file).grep(/#{mac}/).first
      if match
        ip_address = match.split[2]
        break
      end

      sleep 1
    end

    ip_address
  end


end
