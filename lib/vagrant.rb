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

class Vagrant
  def initialize(vagrant_dir, provider)
    @vagrant_dir = vagrant_dir
    @provider = provider
  end

  def run(*args)
    # Many vagrant commands don't have a --provider option, but they fail
    # because they can't find VirtualBox. The following code is a crude
    # workaround.
    Dir.chdir(@vagrant_dir) do
      with_env "VAGRANT_DEFAULT_PROVIDER" => @provider do
        Cheetah.run "vagrant", *args
      end
    end
  end

  def ssh_config(vm_name)
    output = Dir.chdir(@vagrant_dir) do
      if vm_name
        run "ssh-config", vm_name, :stdout => :capture
      else
        config = ""
        status = run "status", :stdout => :capture
        status.scan(/\n(.*?)\s*running/).each do |vm_name|
          config += run "ssh-config", vm_name.first, :stdout => :capture
        end
        config
      end
    end

    parse_ssh_config_output(output)
  end

  private

  def parse_ssh_config_output(output)
    # See http://linux.die.net/man/5/ssh_config for description of the format.

    config = {}
    host = nil

    output.each_line do |line|
      line.chomp!("\n")

      next if line.empty? || line.start_with?("#")

      m = /^\s*(?<key>\w+)(\s*=\s*|\s+)(?<value>.*)$/.match(line)
      raise "Invalid line in SSH config: #{line.inspect}." unless m

      if m[:key] == "Host"
        host = m[:value]
        config[host] = {}
      else
        raise "Missing Host keyword before #{m[:key]}." unless host

        config[host][m[:key]] = m[:value]
      end
    end

    config
  end
end
