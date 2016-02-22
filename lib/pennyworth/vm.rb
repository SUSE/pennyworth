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
  # Represents a virtual machine that can be started, stopped, and interacted
  # with.
  class VM
    attr_accessor :ip, :runner

    class CommandResult
      attr_accessor :stdout, :stderr, :exit_code, :cmd, :error
    end

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
      opts = args.last.is_a?(Hash) ? args.pop : {}

      opts.merge!(
        stdout: :capture,
        stderr: :capture
      )

      result = CommandResult.new
      result.cmd = args.join(" ")
      begin
        stdout, stderr = command_runner.run(*args, opts)
        result.exit_code = 0
        result.stdout = stdout
        result.stderr = stderr
      rescue Cheetah::ExecutionFailed => e
        result.error = e
        result.exit_code = e.status.exitstatus
        result.stdout = e.stdout
        result.stderr = e.stderr
      end

      result
    end

    def inject_file(source, destination, opts = {})
      command_runner.inject_file(source, destination, opts)
    end

    def extract_file(source, destination)
      command_runner.extract_file(source, destination)
    end

    def inject_directory(source, destination, opts = {})
      command_runner.inject_directory(source, destination, opts)
    end

    def has_file?(path)
      command_runner.has_file?(path)
    end

    def cleanup_directory(dir)
      runner.cleanup_directory(dir)
    end

    private

    def command_runner
      @runner.command_runner
    end
  end
end
