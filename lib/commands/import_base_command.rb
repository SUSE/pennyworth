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

class ImportBaseCommand < BaseCommand

  def execute(image_name, options = {})
    @vagrant = VagrantCommand.new
    options = {
      subdir: "",
      local: false
    }.merge(options)

    Pennyworth::Libvirt.ensure_libvirt_env_started

    if options[:local]
      all_images = local_base_images
      box_state = read_local_box_state_file
    else
      all_images = remote_base_images(options[:subdir])
      box_state = read_remote_box_state_file
    end
    import_state = read_import_state_file
    images = process_base_image_parameter(all_images, image_name)
    images.each do |image|
      if box_state[image] && box_state[image]["target"] &&
         import_state[image] &&
         box_state[image]["target"] == import_state[image]
        log "Box '#{image}' hasn't changed since last import. Skipping"
      else
        Dir.chdir Cli.settings.vagrant_dir do
          log "Importing box '#{image}' into vagrant..."
          base_image_clean(image)
          base_image_import(image, options)
          if box_state[image] && box_state[image]["target"]
            import_state[image] = box_state[image]["target"]
          else
            import_state[image] = nil
          end
          write_import_state_file(import_state)
        end
      end
    end
  end

  def read_import_state_file
    import_state_file = File.join(kiwi_dir, "import_state.yaml")
    if File.exist? import_state_file
      import_state = YAML.load_file(import_state_file)
    else
      import_state = {}
    end
    import_state
  end

  def write_import_state_file(import_state)
    FileUtils.mkdir_p(kiwi_dir) unless Dir.exists?(kiwi_dir)

    File.open(File.join(kiwi_dir, "import_state.yaml"), "w") do |f|
      f.write(import_state.to_yaml)
    end
  end

  def read_remote_box_state_file
    box_state_yaml = fetch_remote_box_state_file
    if box_state_yaml
      return YAML.load(box_state_yaml)
    else
      return {}
    end
  end

  private

  def fetch_remote_box_state_file
    url = URLs.join(@remote_url, "box_state.yaml")
    Net::HTTP.get(URI.parse(url))
  end

  def base_image_clean(box)
    Cheetah.run "virsh", "-c", "qemu:///system", "vol-delete", "#{box}_vagrant_box_image.img", "--pool=default"
    Cheetah.run "virsh", "-c", "qemu:///system", "pool-refresh", "--pool=default"
    @vagrant.destroy
  rescue
  end

  # Imports the box into the Vagrant pool so that it can be used for the test
  # environments.
  def base_image_import(box, options)
    if options[:local]
      box_path = File.join(kiwi_dir, box + ".box")
    else
      box_path = URLs.join(@remote_url, options[:subdir], box + ".box")
    end
    @vagrant.add_box(box, box_path)
  end
end
