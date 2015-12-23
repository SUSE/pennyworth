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

RSpec::Matchers.define :fail do
  match do |result|
    if @exit_code
      result.exit_code == @exit_code
    else
      result.exit_code != 0
    end
  end

  chain :with_exit_code do |exit_code|
    @exit_code = exit_code
  end

  failure_message do |result|
    message = "Expected\n    #{result.cmd}\nto fail"
    if @exit_code
      message += " with exit code #{@exit_code} but it exited with #{result.exit_code}"
    else
      message += " but it succeeded."
    end

    message
  end
end

RSpec::Matchers.define :have_stderr do |expected|
  match do |result|
    if expected.is_a?(Regexp)
      expected.match(result.stderr)
    else
      expected == result.stderr
    end
  end

  failure_message do |result|
    if expected.is_a?(Regexp)
      message = "Expected stderr to match #{expected.inspect}"
      message += " (was:\n\n#{(result.stderr)})"
    else
      message = "Expected stderr to be '#{expected}'"
      message += "\n\nDiff of stderr:"
      differ = RSpec::Support::Differ.new(color: true)
      message += differ.diff(result.stderr, expected)
    end

    message
  end
end

RSpec::Matchers.define :include_stderr do |expected|
  match do |result|
    result.stderr.include? expected
  end

  failure_message do |result|
    "Expected stderr '#{result.stderr}' to include '#{expected}'"
  end
  failure_message_when_negated do |result|
    "Expected stderr '#{result.stderr}' to not include '#{expected}'"
  end
end
RSpec::Matchers.define_negated_matcher :not_include_stderr, :include_stderr

RSpec::Matchers.define :have_stdout do |expected|
  match do |result|
    if expected.is_a?(Regexp)
      expected.match(result.stdout)
    else
      expected == result.stdout
    end
  end

  failure_message do |result|
    if expected.is_a?(Regexp)
      message = "Expected stdout to match #{expected.inspect}"
      message += " (was:\n\n#{(result.stdout)})"
    else
      message = "Expected stdout to be '#{expected}'"
      message += "\n\nDiff of stdout:"
      differ = RSpec::Support::Differ.new(color: true)
      message += differ.diff(result.stdout, expected)
    end

    message
  end
end

RSpec::Matchers.define :include_stdout do |expected|
  match do |result|
    result.stdout.include? expected
  end

  failure_message do |result|
    "Expected stdout '#{result.stdout}' to include '#{expected}'"
  end
  failure_message_when_negated do |result|
    "Expected stdout '#{result.stdout}' to not include '#{expected}'"
  end
end
RSpec::Matchers.define_negated_matcher :not_include_stdout, :include_stdout

RSpec::Matchers.define :succeed do
  chain :with_stderr do
    @allow_stderr = true
  end

  chain :with_or_without_stderr do
    @ignore_stderr = true
  end

  match do |result|
    return false if result.exit_code != 0
    return false if !@ignore_stderr && !result.stderr.empty? && !@allow_stderr
    return false if result.stderr.empty? && @allow_stderr

    true
  end

  failure_message do |result|
    message = "Expected\n    #{result.cmd}\nto succeed"
    if result.exit_code != 0
      message += " but it returned with exit code #{result.exit_code}"
    elsif !result.stderr.empty? && !@allow_stderr
      message += " but it had stderr output.\nThe output was:\n#{result.stderr}"
    elsif result.stderr.empty? && @allow_stderr
      message += " with stderr output but stderr was empty."
    end

    message
  end
end
