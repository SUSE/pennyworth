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

# Represents a virtual machine that can be started, stopped, and interacted
# with.
class VM
  attr_accessor :ip

  def initialize(runner)
    @runner = runner
  end

  def start
    @ip = @runner.start
  end

  def stop
    @runner.stop
  end

  def run_command(*args)
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
    escaped_args = args.map { |a| Shellwords.escape(a) }

    if user = options.delete(:as)
      escaped_args = ["su", user, "-c"] + escaped_args
    end

    Cheetah.run(
      "ssh",
      "-o",
      "UserKnownHostsFile=/dev/null",
      "-o",
      "StrictHostKeyChecking=no",
      "root@#{@ip}",
      "LC_ALL=C",
      *escaped_args,
      options
    )
  rescue Cheetah::ExecutionFailed => e
    message = e.message
    message += "\nStandard output:\n #{e.stdout}\n"
    message += "\nError output:\n #{e.stderr}\n"
    raise ExecutionFailed.new(message)
  end

  def inject_file(source, destination)
    Cheetah.run(
      "scp",
      "-o",
      "UserKnownHostsFile=/dev/null",
      "-o",
      "StrictHostKeyChecking=no",
      source,
      "root@#{@ip}:#{destination}"
    )
  rescue Cheetah::ExecutionFailed => e
    message = e.message
    message += "\nStandard output:\n #{e.stdout}\n"
    message += "\nError output:\n #{e.stderr}\n"
    raise ExecutionFailed.new(message)
  end

  def extract_file(source, destination)
    Cheetah.run(
      "scp",
      "-o",
      "UserKnownHostsFile=/dev/null",
      "-o",
      "StrictHostKeyChecking=no",
      "root@#{@ip}:#{source}",
      destination
    )
  rescue Cheetah::ExecutionFailed => e
    message = e.message
    message += "\nStandard output:\n #{e.stdout}\n"
    message += "\nError output:\n #{e.stderr}\n"
    raise ExecutionFailed.new(message)
  end

  def inject_directory(source, destination, opts = {})
    Cheetah.run(
      "scp",
      "-r",
      "-o",
      "UserKnownHostsFile=/dev/null",
      "-o",
      "StrictHostKeyChecking=no",
      source,
      "root@#{@ip}:#{destination}"
    )

    if opts[:owner] || opts[:group]
      owner_group = opts[:owner] || ""
      owner_group += ":#{opts[:group]}" if opts[:group]
      Cheetah.run(
        "ssh",
        "-o",
        "UserKnownHostsFile=/dev/null",
        "-o",
        "StrictHostKeyChecking=no",
        "root@#{@ip}",
        "chown -R #{owner_group} #{destination}/#{File.basename(source)}"
      )
    end
  rescue Cheetah::ExecutionFailed => e
    message = e.message
    message += "\nStandard output:\n #{e.stdout}\n"
    message += "\nError output:\n #{e.stderr}\n"
    raise ExecutionFailed.new(message)
  end
end
