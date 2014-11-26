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

class BaseCommand < Command

  attr_reader :kiwi_dir

  def initialize(kiwi_dir, remote_url = nil)
    super()
    @kiwi_dir = kiwi_dir
    @remote_url = remote_url
  end

  def remote_base_images(subdir = "")
    return [] if !@remote_url || @remote_url.empty?

    uri = URI.parse(URLs.join(@remote_url, subdir, "import_state.yaml"))
    response = Net::HTTP.get_response(uri)
    if response.is_a?(Net::HTTPSuccess)
      index = YAML.load(response.body)
      index.keys
    else
      STDERR.puts "Could not download remote state file at #{uri.to_s}: " + response.message
      exit 1
    end
  end

  def local_base_images
    Dir.glob(File.join(@kiwi_dir, "definitions", "*")).
      select { |f| File.directory?(f) }.
      map { |d| File.basename(d) }
  end

  def process_base_image_parameter(all_images, base_image = nil)
    if !base_image
      return all_images
    end
    if all_images.include?(base_image)
      return [base_image]
    else
      raise "Unknown base image '#{base_image}'. Known images are: #{all_images.join(", ")}."
    end
  end

  def read_box_sources_state(box_name)
    sources = Hash.new
    source_dir = File.join(@kiwi_dir, "definitions", box_name)
    Find.find(source_dir) do |file|
      next if File.directory?(file)
      relative_path = file.gsub(/^#{File.join(source_dir, "/")}/,"")
      sources[relative_path] = Digest::MD5.file(file).hexdigest
    end
    sources
  end

  def read_box_target_state(box_name)
    box_file = File.join(@kiwi_dir, box_name) + ".box"
    if File.exist?(box_file)
      target_state = Digest::MD5.file(box_file).hexdigest
    end
    target_state
  end

  def write_box_state_file(box_state)
    File.open(File.join(@kiwi_dir, "box_state.yaml"), "w") do |f|
      f.write(box_state.to_yaml)
    end
  end

  def read_local_box_state_file
    box_state_file = File.join(@kiwi_dir, "box_state.yaml")
    if File.exist? box_state_file
      box_state = YAML.load_file(box_state_file)
    else
      box_state = {}
    end
    box_state
  end

end
