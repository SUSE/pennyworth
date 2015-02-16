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
  #          [command_map]:: Map which translates commands to their local equivalent, e.g.
  #            {
  #              "machinery" => "/home/tux/src/machinery/bin/machinery"
  #            }
  def initialize(opts = {})
    @command_map = opts[:command_map] || {}
    @env = opts[:env] || {}
  end

  def run(*args)
    command = map_to_local_commands(args)

    with_env(@env) do
      Cheetah.run(
        *command
      )
    end
  rescue Cheetah::ExecutionFailed => e
    raise ExecutionFailed.new(e)
  end

  private

  def map_to_local_commands(commands)
    command_position = commands[0] == "sudo" ? 1 : 0
    if @command_map[commands[command_position]]
      commands[command_position] = @command_map[commands[command_position]]
    end

    commands
  end
end
