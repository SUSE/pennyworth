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

class BuildBaseCommand < BaseCommand

  def initialize(veewee_dir)
    super
  end

  def execute(image_name = nil)
    Pennyworth::Libvirt.ensure_libvirt_env_started

    box_state = read_local_box_state_file
    images = process_base_image_parameter(local_base_images, image_name)
    log "Creating base images..."
    images.each do |image|
      Dir.chdir veewee_dir do
        log
        log "--- #{image} ---"
        source_state = read_box_sources_state(image)
        if box_state[image] && box_state[image]["sources"] &&
           source_state && box_state[image]["sources"] == source_state
          log "  Sources not changed, skipping build"
        else
          log "  Building base image..."
          base_image_create(image)
          log "  Validating base image..."
          base_image_halt(image)
          log "  Exporting image as box for vagrant..."
          base_image_export(image)

          box_state[image] = {
            "sources" => source_state,
            "target" => read_box_target_state(image)
          }
          write_box_state_file(box_state)
        end
      end
    end
  end

  private

  # Creates a KVM image from the according Veewee definitions.
  # See pennyworth/veewee/definitions for the definitions we use.
  def base_image_create(box)
    Cheetah.run "veewee", "kvm", "build", box, "--force", "--auto"
  end

  # Stops the KVM image which was brought up by Veewee during the Veewee build.
  def base_image_halt(box)
    Cheetah.run "veewee", "kvm", "halt", box
  end

  # Bundles the built KVM image into a Vagrant .box file using Veewee so that
  # it can be imported by Vagrant.
  def base_image_export(box)
    Cheetah.run "veewee", "kvm", "export", box, "--force"
  end

end
