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

  def initialize(kiwi_dir)
    super
  end

  def execute(tmp_dir, image_name = nil)
    Pennyworth::Libvirt.ensure_libvirt_env_started

    box_state = read_local_box_state_file
    images = process_base_image_parameter(local_base_images, image_name)
    log "Creating base images..."
    images.each do |image|
      Dir.chdir kiwi_dir do
        log
        log "--- #{image} ---"
        source_state = read_box_sources_state(image)
        if box_state[image] && box_state[image]["sources"] &&
           source_state && box_state[image]["sources"] == source_state
          log "  Sources not changed, skipping build"
        else
          description_dir = File.join(kiwi_dir, "definitions", image)
          log "  Building base image..."
          base_image_create(description_dir, tmp_dir)
          log "  Exporting image as box for vagrant..."
          base_image_export(description_dir, tmp_dir)
          base_image_cleanup_build(tmp_dir)

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

  # Creates a KVM image from the according Kiwi description.
  # See pennyworth/kiwi/definitions for the definitions we use.
  def base_image_create(description_dir, tmp_dir)
    FileUtils.mkdir_p(tmp_dir)
    logfile = "#{tmp_dir}/kiwi-terminal-output.log"
    log "    The build log is available under #{logfile}"
    begin
      Cheetah.run "sudo", "/usr/sbin/kiwi", "--build", description_dir,
        "--destdir", tmp_dir, "--logfile", "#{logfile}",
        :stdout => :capture
      rescue Cheetah::ExecutionFailed => e
        raise ExecutionFailed.new(e)
      end
  end

  def base_image_export(description_dir, tmp_dir)
    Dir.chdir(tmp_dir) do
      image = Dir.glob("*.box").first
      if image
        from_file = File.join(tmp_dir, image)
        to_file = description_dir.gsub(/\/$/,"") + ".box"
        begin
          Cheetah.run "sudo", "mv", from_file, to_file, :stdout => :capture
        rescue Cheetah::ExecutionFailed => e
          raise ExecutionFailed.new(e)
        end
      else
        raise BuildFailed, "The built image couldn't be found."
      end
    end
  end

  def base_image_cleanup_build(tmp_dir)
    if (tmp_dir.start_with?("/tmp/"))
      begin
        Cheetah.run "sudo", "rm", "-r", tmp_dir, :stdout => :capture
        rescue Cheetah::ExecutionFailed => e
          raise ExecutionFailed.new(e)
        end
    else
      log " Warning: The KIWI tmp dir #{tmp_dir} was outside of '/tmp' so it" \
        " wasn't removed!"
    end
  end
end
