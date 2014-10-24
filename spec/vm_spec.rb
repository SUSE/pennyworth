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

require "spec"

describe "Pennyworth rspec helper" do
  it "can start the system under test" do
    $vm = start_system(box: "opensuse131")
  end

  it "can inject a file" do
    File.open("/tmp/helper.sh", "w") do |file|
      file.write("#! /bin/bash

echo 'first output line'
echo 'first error line' >&2
echo 'second output line'
echo 'second error line' >&2
")
    end
    $vm.inject_file("/tmp/helper.sh", "./", mode: "+x")
    File.delete("/tmp/helper.sh")
  end

  it "can extract files" do
    $vm.extract_file("/etc/SuSE-release", "/tmp")
    File.open("/tmp/SuSE-release", "rb") do |file|
      $out = file.read
    end
    expect($out).to start_with("openSUSE 13.1 (x86_64)")
    File.delete("/tmp/SuSE-release")
  end

  it "can inject directories" do
# TBD
  end

  it "can capture output to a variable" do
    $out = $vm.run_command("ls -l /", :stdout => :capture)
    expect($out).to match(/ etc$/)
  end

  it "can capture errors to a variable" do
    $err = $vm.run_command("./helper.sh", :stderr => :capture)
    expect($err).to include("first error line\nsecond error line\n")
  end

  it "can capture output and errors to a variable" do
    $out, $err = $vm.run_command("./helper.sh", :stdout => :capture, :stderr => :capture)
    expect($out).to eq("first output line\nsecond output line\n")
    expect($err).to include("first error line\nsecond error line\n")
  end

  it "does escape shell variables" do
    $out = $vm.run_command("echo -n $HOME", :stdout => :capture)
    # '$HOME' and not '/home/testuser'!
    expect($out).to eq("$HOME")
  end

  it "can capture output to a file" do
    File.open("/tmp/out_test.txt", "w") do |file|
      $vm.run_command("./helper.sh", :stdout => file)
    end
    File.open("/tmp/out_test.txt", "rb") do |file|
      expect(file.read).to eq("first output line\nsecond output line\n")
    end
    File.delete("/tmp/out_test.txt")
  end

  it "can capture errors to a file" do
    File.open("/tmp/err_test.txt", "w") do |file|
      $vm.run_command("./helper.sh", :stderr => file)
    end
    File.open("/tmp/err_test.txt", "rb") do |file|
      expect(file.read).to end_with("first error line\nsecond error line\n")
    end
    File.delete("/tmp/err_test.txt")
  end

  it "raises exceptions on errors" do
    begin
      $vm.run_command("ls -l /bang")
      $out = "We should not reach this point."
    rescue ExecutionFailed => e
      $out = e.message()
    end
    expect($out).to end_with("ls: cannot access /bang: No such file or directory\n\n")
  end

#  it "can take input from a string variable" do
#    $out = $vm.run_command("cat", :stdin => "Hello\nWorld!\n", :stdout => :capture)
#    expect($out).to eq("Hello\nWorld!\n")
#  end

  it "can take input from a file" do
    File.open("/etc/passwd", "r") do |pw_file|
      $out = $vm.run_command("cat", :stdin => pw_file, :stdout => :capture)
      expect($out).to match(/^root:x:0:0:root/)
    end
  end
end

RSpec.configure do |config|
  config.vagrant_dir = File.expand_path("examples/vagrant")
end
