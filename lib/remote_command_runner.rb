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
class RemoteCommandRunner
  def initialize(ip)
    @ip = ip
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
      "-o",
      "UserKnownHostsFile=/dev/null",
      "-o",
      "StrictHostKeyChecking=no",
      "root@#{@ip}",
      "LC_ALL=C",
      *args,
      options
    )
  rescue Cheetah::ExecutionFailed => e
    raise ExecutionFailed.new(e)
  end
end
