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

# The purpose of this class is to execute commands on a remote machine via SSH.
module Pennyworth
  class RemoteCommandRunner
    def initialize(ip, username)
      @ip = ip
      @username = username
    end

    def run(*args)
      # When ssh executes commands, it passes them through shell expansion.
      # For example, compare
      #
      #   $ echo '$HOME'
      #   $HOME
      #
      # with
      #
      #   $ ssh localhost echo '$HOME'
      #   /home/dmajda
      #
      # To mitigate that and maintain usual Cheetah semantics, we need to
      # protect the command and its arguments using another layer of escaping.
      options = args.last.is_a?(Hash) ? args.pop : {}
      args.map! { |a| Shellwords.escape(a) } if !options[:skip_escape]

      if user = options.delete(:as)
        args = ["su", "-l", user, "-c"] + args
      end

      Cheetah.run(
        "ssh",
        "-q",
        "-o",
        "UserKnownHostsFile=/dev/null",
        "-o",
        "StrictHostKeyChecking=no",
        "#{@username}@#{@ip}",
        "LC_ALL=C",
        *args,
        options
      )
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
      destination += File.basename(source) if destination.end_with?("/")

      Cheetah.run(
        "scp",
        "-o",
        "UserKnownHostsFile=/dev/null",
        "-o",
        "StrictHostKeyChecking=no",
        source,
        "#{@username}@#{@ip}:#{destination}"
      )

      if opts[:owner] || opts[:group]
        owner_group = opts[:owner] || ""
        owner_group += ":#{opts[:group]}" if opts[:group]
        run "chown", "-R", owner_group, destination
      end

      if opts[:mode]
        run "chmod", opts[:mode], destination
      end
    rescue Cheetah::ExecutionFailed => e
      raise ExecutionFailed.new(e)
    end

    def extract_file(source, destination)
      Cheetah.run(
        "scp",
        "-o",
        "UserKnownHostsFile=/dev/null",
        "-o",
        "StrictHostKeyChecking=no",
        "#{@username}@#{@ip}:#{source}",
        destination
      )
    rescue Cheetah::ExecutionFailed => e
      raise ExecutionFailed.new(e)
    end

    def inject_directory(source, destination, opts = {})
      if opts[:owner] || opts[:group]
        owner_group = opts[:owner] || ""
        owner_group += ":#{opts[:group]}" if opts[:group]
      end

      chown_cmd = " && chown #{owner_group} '#{destination}'" if owner_group
      mkdir_cmd = "test -d '#{destination}' || (mkdir -p '#{destination}' #{chown_cmd} )"

      run mkdir_cmd, skip_escape: true

      Cheetah.run(
        "scp",
        "-r",
        "-o",
        "UserKnownHostsFile=/dev/null",
        "-o",
        "StrictHostKeyChecking=no",
        source,
        "#{@username}@#{@ip}:#{destination}"
      )

      if owner_group
        run "chown", "-R", owner_group, File.join(destination, File.basename(source))
      end
    rescue Cheetah::ExecutionFailed => e
      raise ExecutionFailed.new(e)
    end

    def has_file?(path)
      Cheetah.run(
        "ssh",
        "-q",
        "-o",
        "UserKnownHostsFile=/dev/null",
        "-o",
        "StrictHostKeyChecking=no",
        "#{@username}@#{@ip}",
        "LC_ALL=C",
        "test -f #{path}"
      )
      return true
    rescue Cheetah::ExecutionFailed
      return false
    end
  end
end
