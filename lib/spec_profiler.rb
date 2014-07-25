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

require "benchmark"

def measure(label, &block)
  own_parent = @parent_measurement
  measurement = {
      label: label,
      child_measurements: []
  }

  @parent_measurement = measurement
  time = Benchmark.measure do
    block.call
  end
  @parent_measurement = own_parent
  measurement.merge!(time: time.real)

  # Calculate time that was not spent in the measured child blocks but somewhere
  # else
  if !measurement[:child_measurements].empty?
    other_time = measurement[:time]
    measurement[:child_measurements].each do |child|
      other_time -= child[:time]
    end
    measurement[:child_measurements] << { label: "Other", time: other_time }
  end

  if own_parent
    own_parent[:child_measurements] << measurement
  else
    @measurements << measurement
  end
end

def print_measurement(measurement, indent = 0)
  name = measurement[:label][0..65-indent].ljust(70-indent)
  STDERR.puts (" " * indent) + "#{name}: #{measurement[:time]}"

  if measurement[:child_measurements]
    measurement[:child_measurements].each do |child|
      print_measurement(child, indent + 2)
    end
  end
end

RSpec.configure do |config|
  config.before(:all) do
    @measurements = []
  end

  config.around(:each) do |example|
    if RSpec.configuration.pennyworth_mode
      example.run
    else
      measure(example.metadata[:full_description]) do
        example.run
      end
    end
  end

  config.after(:all) do
    if !RSpec.configuration.pennyworth_mode
      @measurements.each do |measurement|
        print_measurement(measurement)
      end
    end
  end
end

