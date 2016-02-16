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

module Pennyworth
  # LocalCommandRunner is used for executing commands on the local machine
  class LocalCommandRunner
    # Initialize the command runner
    #
    # +opts+:: Options to modify how and which the commands are run.
    #
    #          Available options:
    #          [env]:: Hash of environment options to set for the command, e.g.
    #            {
    #              "MACHINERY_DIR" => "/tmp/machinery"
    #            }
    def initialize(opts = {})
      @env = opts[:env] || {}
    end

    def run(*args)
      options = args.last.is_a?(Hash) ? args.pop : {}

      with_env(@env) do
        Cheetah.run(
          "bash", "-c", *args, options
        )
      end
    end

    # Copy a local file to the remote system.
    #
    # +source+:: Path to the local file
    # +destination+:: Path to the remote file or directory. If +destination+ is a
    #                 path, the same filename as +source+ will be used.
    # +opts+:: Options to modify the attributes of the remote file.
    #
    #          Available options:
    #          [owner]:: Owner of the file, e.g. "tux"
    #          [group]:: Group of the file, e.g. "users"
    #          [mode]:: Mode of the file, e.g. "600"
    def inject_file(source, destination, opts = {})
      # Append filename (taken from +source+) to destination if it is a path, so
      # that +destination+ is always the full target path including the filename.
      destination = File.join(destination, File.basename(source)) if File.directory?(destination)

      FileUtils.cp(source, destination)
      FileUtils.chown(opts[:owner], opts[:group], destination)
      FileUtils.chmod(opts[:mode], destination) if opts[:mode]
    end

    def extract_file(source, destination)
      FileUtils.cp(source, destination)
    end

    def inject_directory(source, destination, opts = {})
      FileUtils.mkdir_p(destination)
      FileUtils.cp_r(source, destination)
      FileUtils.chown_R(opts[:owner], opts[:group], destination)
    end

    def has_file?(path)
      begin
        Cheetah.run("test", "-f", path)
        return true
      rescue Cheetah::ExecutionFailed
        return false
      end
    end
  end
end
