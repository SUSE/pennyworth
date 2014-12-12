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

require "twopence"

# Represents a virtual machine that can be started, stopped,
# and interacted with.
class TwopenceVM
  attr_accessor :ip

  def initialize(runner)
    @runner = runner
  end

  # TODO: currently, the rspec helpers communicate with the VM machine
  # through SSH, but Twopence can use other methods, for example virtio.
  # Find a way to extract the virtio-serial information from the VM,
  # when it exists, so we can pass it over to Twopence.
  def start
    @ip = @runner.start
    @target = Twopence::init("ssh:#{@ip}")
  end

  def stop
    @runner.stop
  end

  # Run command - Twopence syntax
  #
  # +user+:: user running the command
  # +command+:: command to be run, as one string
  def test_and_print_results(user, command)
    @target.test_and_print_results(user, command)
  end

  def test_and_drop_results(user, command)
    @target.test_and_drop_results(user, command)
  end

  def test_and_store_results_together(user, command)
    @target.test_and_store_results_together(user, command)
  end

  def test_and_store_results_separately(user, command)
    @target.test_and_store_results_separately(user, command)
  end

  # Run command - Cheetah syntax
  #
  # +command, arg1, arg2...+:: command to be run and its arguments
  #                            the arguments are escaped, so $HOME remains "$HOME" and not "/home/someuser"
  #
  #          Available options:
  #          [as]:: user running the command
  #          [stdin]:: command's standard input, as a string or a file stream
  #          [stdout]:: command's standard output, as a file stream or :capture to get it in a variable
  #          [stderr]:: command's standard error, as a file stream or :capture to get it in a variable
  def run_command(*args)
    # Parse options
    options = args.last.is_a?(Hash) ? args.pop : {}
    args_string = ""
    args.each do |a|
      a.split(" ").each do |w|
        args_string += Shellwords.escape(w) + " "
      end
    end
    if not(user = options[:as])
      user = "root"
    end
    input = options[:stdin]
    output = options[:stdout]
    error = options[:stderr]

    # Redirect standard input
    if input
      saved_stdin = $stdin.dup
      if input.is_a? File
        $stdin.reopen(input)
      elsif input.is_a? String
        # stdin can't be redirected to a StringIO, so we raise an exception for now
        # To implement this, we could store the string in a file, and continue with that file :-(
        raise ExecutionFailed.new("Redirecting stdin from a string is currently unsupported")
      end
    end

    # Run command
    out, err, rc, major, minor = @target.test_and_store_results_separately(user, args_string)

    # Redirect back standard input
    if input
      $stdin.reopen(saved_stdin)
    end

    # Write output and error to files if requested
    if output.is_a? File
      output.write(out)
    end
    if error.is_a? File
      error.write(err)
    end

    # Raise exceptions in case of errors
    if rc != 0
      out = ""
      err = "Twopence local error"
      e = Cheetah::ExecutionFailed.new(
            args_string, rc, out, err,
            "Execution of \"#{args_string}\" failed with status #{rc}:\n")
      raise ExecutionFailed.new(e)
    end
    if major != 0
      out = ""
      err = "Twopence remote error"
      e = Cheetah::ExecutionFailed.new(
            args_string, major, out, err,
            "Execution of \"#{args_string}\" failed with status #{major}:\n")
      raise ExecutionFailed.new(e)
    end
    if minor != 0
      e = Cheetah::ExecutionFailed.new(
            args_string, minor, out, err,
            "Execution of \"#{args_string}\" failed with status #{minor}:\n")
      raise ExecutionFailed.new(e)
    end

    # Otherwise, return values as requested
    if output == :capture and error == :capture
        return [out, err]
    end
    if output == :capture
      return out
    end
    if error == :capture
      return err
    end
  end

  # Copy a local file to the remote system - Twopence syntax.
  #
  # +user+:: user running the command
  # +local_file+:: source file on the local system
  # +remote_file+:: destination file on the remote system
  # +dots+:: display progression dots if true
  def inject_file(user, local_file, remote_file, dots)
    @target.inject_file(user, local_file, remote_file, dots)
  end

  # Copy a local file to the remote system - Cheetah syntax.
  #
  # +source+:: path to the local file
  # +destination+:: path to the remote file or directory
  #                 if +destination+ is a path, the same filename as +source+ will be used
  # +opts+:: Options to modify the attributes of the remote file
  #
  #          Available options:
  #          [owner]:: Owner of the file, e.g. "tux"
  #          [group]:: Group of the file, e.g. "users"
  #          [mode]:: Mode of the file, e.g. "600"
  def inject_file(source, destination, opts = {})
    # Parse options
    if destination.end_with?("/")
      destination += File.basename(source)
    end
    command = ""
    if opts[:owner] or opts[:group]
      command += "chown "
      if opts[owner]
        command += opts[:owner]
      end
      if opts[:group]
        command += ":" + opts[:group]
      end
      command += " " + destination
    end
    if opts[:mode]
      if command != ""
        command += " && "
      end
      command += "chmod " + opts[:mode] + " " + destination
    end

    # Transfer the file
    rc, major = @target.inject_file("root", source, destination, false)
    if rc != 0
      command = ""
      out = ""
      err = "Twopence local error"
      e = Cheetah::ExecutionFailed.new(
            command, rc, out, err,
            "Transfer of \"#{source}\" to \"#{destination}\" failed with status #{rc}:\n")
      raise ExecutionFailed.new(e)
    end
    if major != 0
      command = ""
      out = ""
      err = "Twopence remote error"
      e = Cheetah::ExecutionFailed.new(
            command, major, out, err,
            "Transfer of \"#{source}\" to \"#{destination}\" failed with status #{major}:\n")
      raise ExecutionFailed.new(e)
    end

    # Change its owner and permissions if requested
    if command != ""
      out, err, rc, major, minor = @target.test_and_store_results_separately("root", command)
      if rc != 0
        out = ""
        err = "Twopence local error"
        e = Cheetah::ExecutionFailed.new(
              command, rc, out, err,
              "Execution of \"#{command}\" failed with status #{rc}:\n")
        raise ExecutionFailed.new(e)
      end
      if major != 0
        out = ""
        err = "Twopence remote error"
        e = Cheetah::ExecutionFailed.new(
              command, major, out, err,
              "Execution of \"#{command}\" failed with status #{major}:\n")
        raise ExecutionFailed.new(e)
      end
      if minor != 0
        e = Cheetah::ExecutionFailed.new(
              command, minor, out, err,
              "Execution of \"#{command}\" failed with status #{minor}:\n")
        raise ExecutionFailed.new(e)
      end
    end
  end

  # Copy a remote file to the local system - Twopence syntax.
  #
  # +user+:: user running the command
  # +remote_file+:: source file on the remote system
  # +local_file+:: destination file on the local system
  # +dots+:: display progression dots if true
  def extract_file(user, remote_file, local_file, dots)
    @target.extract_file(user, remote_file, local_file, dots)
  end

  # Copy a remote file to the local system - Cheetah syntax.
  #
  # +source+:: path to the remote file
  # +destination+:: path to the local file or directory.
  def extract_file(source, destination)
    # Parse options
    if File.directory?(destination)
      if destination.end_with?("/")
        destination += File.basename(source)
      else
        destination += "/" + File.basename(source)
      end
    end

    # Transfer the file
    rc, major = @target.extract_file("root", source, destination, false)
    if rc != 0
      command = ""
      out = ""
      err = "Twopence local error"
      e = Cheetah::ExecutionFailed.new(
            command, rc, out, err,
            "Transfer of \"#{source}\" to \"#{destination}\" failed with status #{rc}:\n")
      raise ExecutionFailed.new(e)
    end
    if major != 0
      command = ""
      out = ""
      err = "Twopence remote error"
      e = Cheetah::ExecutionFailed.new(
            command, major, out, err,
            "Transfer of \"#{source}\" to \"#{destination}\" failed with status #{major}:\n")
      raise ExecutionFailed.new(e)
    end
  end

# TBD ******************************************************************** TBD
  def inject_directory(source, destination, opts = {})
    if opts[:owner] || opts[:group]
      owner_group = opts[:owner] || ""
      owner_group += ":#{opts[:group]}" if opts[:group]
    end

    chown_cmd = " && chown #{owner_group} '#{destination}'" if owner_group
    mkdir_cmd = "test -d '#{destination}' || (mkdir -p '#{destination}' #{chown_cmd} )"
    Cheetah.run(
      "ssh",
      "-o",
      "UserKnownHostsFile=/dev/null",
      "-o",
      "StrictHostKeyChecking=no",
      "root@#{@ip}",
      mkdir_cmd
    )

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

    if owner_group
      Cheetah.run(
        "ssh",
        "-o",
        "UserKnownHostsFile=/dev/null",
        "-o",
        "StrictHostKeyChecking=no",
        "root@#{@ip}",
        "chown -R #{owner_group} " \
          "#{File.join(destination, File.basename(source))}"
      )
    end
  rescue Cheetah::ExecutionFailed => e
    raise ExecutionFailed.new(e)
  end
end
