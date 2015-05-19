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

require "spec_helper"

describe Pennyworth::Vagrant do
  describe "#ssh_config" do
    def unindent(s)
      indent = " " * (s.split("\n").map { |l| l.match(/^\s*/)[0].size }.min || 0)
      s.gsub(/^#{indent}/, "")
    end

    subject { Pennyworth::Vagrant.new("/tmp") }

    let(:vagrant_ssh_config_output_one) {
      unindent(<<-EOT)
        Host one
          HostName 192.168.122.1
          User vagrant
          Port 22
          UserKnownHostsFile /dev/null
          StrictHostKeyChecking no
          PasswordAuthentication no
          IdentityFile /home
          IdentitiesOnly yes
          LogLevel FATAL
      EOT
    }

    let(:vagrant_ssh_config_output_two) {
      unindent(<<-EOT)
        Host two
          HostName 192.168.122.2
          User vagrant
          Port 22
          UserKnownHostsFile /dev/null
          StrictHostKeyChecking no
          PasswordAuthentication no
          IdentityFile /home
          IdentitiesOnly yes
          LogLevel FATAL
      EOT
    }

    let(:vagrant_ssh_config_output_three) {
      unindent(<<-EOT)
        Host three
          HostName 192.168.122.3
          User vagrant
          Port 22
          UserKnownHostsFile /dev/null
          StrictHostKeyChecking no
          PasswordAuthentication no
          IdentityFile /home
          IdentitiesOnly yes
          LogLevel FATAL
      EOT
    }

    let(:vagrant_ssh_config_output_all) {
      [
        vagrant_ssh_config_output_one,
        vagrant_ssh_config_output_two,
        vagrant_ssh_config_output_three
      ].join("")
    }

    let(:vagrant_ssh_config_output_empty_line) {
      unindent(<<-EOT)
        Host empty-line

        HostName 192.168.122.1
      EOT
    }

    let(:vagrant_ssh_config_output_comment) {
      unindent(<<-EOT)
        Host comment
        # comment
        HostName 192.168.122.1
      EOT
    }

    let(:vagrant_ssh_config_output_formatting) {
      unindent(<<-EOT)
        Host formatting
        A a
         B b
           C c
        D   d
        E=e
        F =f
        G   =g
        H= h
        I=   i
      EOT
    }

    let(:vagrant_ssh_config_output_invalid_line) {
      unindent(<<-EOT)
        invalid
      EOT
    }

    let(:vagrant_ssh_config_output_missing_host) {
      unindent(<<-EOT)
        HostName 192.168.122.1
      EOT
    }

    let(:vagrant_status_output) {
      unindent(<<-EOT)
        Current machine states:

        \none                    running (libvirt)
        \ntwo                    running (libvirt)
        \nthree                  running (libvirt)

        This environment represents multiple VMs. The VMs are all listed
        above with their current state. For more information about a specific
        VM, run `vagrant status NAME`.
      EOT
    }

    let(:ssh_config_one) {
      {
        "one" => {
          "HostName"               => "192.168.122.1",
          "User"                   => "vagrant",
          "Port"                   => "22",
          "UserKnownHostsFile"     => "/dev/null",
          "StrictHostKeyChecking"  => "no",
          "PasswordAuthentication" => "no",
          "IdentityFile"           => "/home",
          "IdentitiesOnly"         => "yes",
          "LogLevel"               => "FATAL"
        }
      }
    }

    let(:ssh_config_two) {
      {
        "two" => {
          "HostName"               => "192.168.122.2",
          "User"                   => "vagrant",
          "Port"                   => "22",
          "UserKnownHostsFile"     => "/dev/null",
          "StrictHostKeyChecking"  => "no",
          "PasswordAuthentication" => "no",
          "IdentityFile"           => "/home",
          "IdentitiesOnly"         => "yes",
          "LogLevel"               => "FATAL"
        }
      }
    }

    let(:ssh_config_three) {
      {
        "three" => {
          "HostName"               => "192.168.122.3",
          "User"                   => "vagrant",
          "Port"                   => "22",
          "UserKnownHostsFile"     => "/dev/null",
          "StrictHostKeyChecking"  => "no",
          "PasswordAuthentication" => "no",
          "IdentityFile"           => "/home",
          "IdentitiesOnly"         => "yes",
          "LogLevel"               => "FATAL"
        }
      }
    }

    let(:ssh_config_all) {
      ssh_config_one.merge(ssh_config_two).merge(ssh_config_three)
    }

    let(:ssh_config_empty_line) {
      {
        "empty-line" => { "HostName" => "192.168.122.1" }
      }
    }

    let(:ssh_config_comment) {
      {
        "comment" => { "HostName" => "192.168.122.1" }
      }
    }

    let(:ssh_config_formatting) {
      {
        "formatting" => {
          "A" => "a",
          "B" => "b",
          "C" => "c",
          "D" => "d",
          "E" => "e",
          "F" => "f",
          "G" => "g",
          "H" => "h",
          "I" => "i"
        }
      }
    }

    it "reads SSH config of one box correctly" do
      expect(Cheetah).to receive(:run).
        with("vagrant", "ssh-config", "one", :stdout => :capture).
        and_return(vagrant_ssh_config_output_one)

      expect(subject.ssh_config("one")).to eq(ssh_config_one)
    end

    it "reads SSH config of all boxes correctly" do
      expect(Cheetah).to receive(:run).
        with("vagrant", "status", :stdout => :capture).
        and_return(vagrant_status_output)
      expect(Cheetah).to receive(:run).
        with("vagrant", "ssh-config", "one", :stdout => :capture).
        and_return(vagrant_ssh_config_output_one)
      expect(Cheetah).to receive(:run).
        with("vagrant", "ssh-config", "two", :stdout => :capture).
        and_return(vagrant_ssh_config_output_two)
      expect(Cheetah).to receive(:run).
        with("vagrant", "ssh-config", "three", :stdout => :capture).
        and_return(vagrant_ssh_config_output_three)

      expect(subject.ssh_config(nil)).to eq(ssh_config_all)
    end

    it "ignores empty lines" do
      expect(Cheetah).to receive(:run).
        with("vagrant", "ssh-config", "empty-line", :stdout => :capture).
        and_return(vagrant_ssh_config_output_empty_line)

      expect(subject.ssh_config("empty-line")).to eq(ssh_config_empty_line)
    end

    it "ignores comments" do
      expect(Cheetah).to receive(:run).
        with("vagrant", "ssh-config", "comment", :stdout => :capture).
        and_return(vagrant_ssh_config_output_comment)

      expect(subject.ssh_config("comment")).to eq(ssh_config_comment)
    end

    it "ignores formatting variations" do
      expect(Cheetah).to receive(:run).
        with("vagrant", "ssh-config", "formatting", :stdout => :capture).
        and_return(vagrant_ssh_config_output_formatting)

      expect(subject.ssh_config("formatting")).to eq(ssh_config_formatting)
    end

    it "raises an exception when encountering an invalid line" do
      expect(Cheetah).to receive(:run).
        with("vagrant", "ssh-config", "invalid-line", :stdout => :capture).
        and_return(vagrant_ssh_config_output_invalid_line)

      expect {
        subject.ssh_config("invalid-line")
      }.to raise_error("Invalid line in SSH config: \"invalid\".")
    end

    it "raises an exception when the Host keyword is missing" do
      expect(Cheetah).to receive(:run).
        with("vagrant", "ssh-config", "missing-host", :stdout => :capture).
        and_return(vagrant_ssh_config_output_missing_host)

      expect {
        subject.ssh_config("missing-host")
      }.to raise_error("Missing Host keyword before HostName.")
    end
  end
end
