# Pennyworth

[![Code Climate](https://codeclimate.com/github/SUSE/pennyworth/badges/gpa.svg)](https://codeclimate.com/github/SUSE/pennyworth)

Pennyworth is a tool for running integration tests inside a network of virtual
machines. It allows the user to define virtual machines, build them as Vagrant
boxes and run them using libvirt and kvm in a coordinated fashion in order to
run the tests.
These tests can be written in any language/framework, but the preferred
combination is Ruby/RSpec, for which helpers are provided.

Pennyworth is a spin-off of the
[Machinery project](http://machinery-project.org). It is used there to manage
the environment of the integration tests.

## Contents

  * [Installation](#installation)
  * [Overview](#overview)
    - [Defining and Building Machines](#defining-and-building-machines)
    - [Running Boxes](#running-boxes)
  * [Usage](#usage)
    - [Command Line](#command-line)
    - [RSpec Helper](#rspec-helper)
  * [Terminology](#terminology)
  * [Further Information](#further-information)

## Installation

Pennyworth is tested on [openSUSE 13.1](http://en.opensuse.org/Portal:13.1).
It may not work with other openSUSE versions, Linux distributions, or
operating systems.

The following steps will make Pennyworth run on a vanilla openSUSE 13.1 system.

  1. **Install required packages**

     Install Git:

         $ sudo zypper in git

     Install basic Ruby environment:

         $ sudo zypper in ruby rubygem-bundler

     After the installation, make sure that your `ruby20` version is at least
     `2.0.0.p247-3.11.1`:

         $ rpm -q ruby20

     With lower versions, `bundle install` won't work because of a
     [bug](https://bugzilla.novell.com/show_bug.cgi?id=858100).

     Install packages needed to detect a base system:

         $ sudo zypper in lsb-release

     Install packages needed to compile Gems with native extensions:

         $ sudo zypper in gcc-c++ make ruby-devel libvirt-devel libxslt-devel libxml2-devel

  2. **Clone Pennyworth repository and install Gem dependencies required to run
     the setup**

         $ git clone git@github.com:SUSE/pennyworth.git
         $ cd pennyworth
         $ bundle config build.nokogiri --use-system-libraries
         $ bundle install --without test

  3. **Run the setup**

         $ bin/pennyworth setup

  4. **Install remaining Gem dependencies**

         $ bundle install --without ""

     Specifying an empty value with `--without ""` is necessary because this
     option is “remembered”. If absent, Bundler would use its value from the
     last invocation (`test`).

  5. **Restart your system**

     This refreshes information about current user's groups and network setup.

  6. **Done!**

     You can now start using Pennyworth.

## Overview

Pennyworth is a command-line tool built around defining virtual machines,
building them, and running integration tests on them.

The usual workflow is:

  1. Define machines used to run integration tests and build them. The result
     is a [Vagrant](http://www.vagrantup.com/) box.

  2. Import built boxes into Vagrant.

  3. Run the boxes as needed and execute your test on them. Ruby users can use a
     RSpec helper to simplify this step.

All these tasks are driven by commands described in the [Usage](#usage) section.

### Defining and Building Machines

To define and build machines, Pennyworth uses
[Veewee](https://github.com/jedi4ever/veewee).

When a machine is built, the resulting Vagrant box can be uploaded to a web
server (manually). Pennyworth running on some other machine can then import it
instead of using a locally-built box, which can save time and ensure everyone
has exactly the same environment for running tests.

### Running Boxes

To run the boxes, Pennyworth uses Vagrant. However, instead of the default
VirtualBox backend it uses KVM driven by libvirt. The theory is that using open
source and SUSE-supported technology will be more reliable and performant, which
should outweigh the somewhat complicated setup.

## Usage

### Command Line

Pennyworth is a command-line tool. You can invoke it by using the `bin/pennyworth`
command. It accepts subcommands (similarly to `git` or `bundle`).

For example:

  - Building an image
    `$pennyworth build_base example_image --definitions-dir=example_dir`

  - Listing availabe VMs
    `$pennyworth list --definitions-dir=example_dir`

  - Starting a VM
    `$pennyworth up my_machine`

For more information about the commands, see the Pennyworth man page.

### RSpec Helper

Pennyworth contains an RSpec helper that helps with running integration tests
using Pennyworth.

To use the helper, first require it:

```ruby
require "<pennyworth-dir>/lib/spec"
```

Replace `<pennyworth-dir>` with a directory into which you installed Pennyworth.

In your specs, you can now use the `start_system` method to start a VM:

```ruby
describe "my pet feature" do
  it "works flawlessly" do
    vm = start_system(box: "box")

    # ...
  end
end
```

The `start_system` method can either start an existing Vagrant box or a generic
VM image runnable by libvirt. To start a Vagrant box, pass its name using the
`box` option. To start a generic VM image, pass its path using the `image`
option.

The `start_system` method returns a `VM` instance, which can be used to interact
with the running machine (via SSH). It supports the following methods:

  * `stop`

    Stops the machine.

  * `run_command(command, *args, options = {})`
    `run_command(command_and_args, options = {})`

    Executes a command on the running machine. The execution is implemented
    using [Cheetah](https://github.com/opensuse/cheetah) and the `run_command`
    method behaves mostly the same as
    [`Cheetah.run`](http://rubydoc.info/github/openSUSE/cheetah/master/Cheetah.run).

  * `inject_file(source, destination)`

    Injects a file from the machine running the specs into the VM.

  * `inject_directory(source, destination, opts = {})`

    Injects a file from the machine running the specs into the VM. The `:owner`
    and `:group` options can be used to set the owner and the group of injected
    files.

  * `extract_file(source, destination)`

    Extracts a file from the VM into the machine running the specs.

All machines started by `start_system` are stopped when the RSpec example group
containing the call is finished.

## Terminology

(Vagrant) Box
: Base image used as a package format for Vagrant environments. Provides an
identical working environment on any platform. For more information please
visit the [Vagrant documentation](http://docs.vagrantup.com/v2/boxes.html)

VM
: Virtual machine ran in KVM. Pennyworth supports running VMs described in a
Vagrantfile as well as non vagrant managed ones.

## Further information

Further information like a [FAQ](https://github.com/SUSE/pennyworth/wiki/Debugging)
or a [Troubleshooting guide](https://github.com/SUSE/pennyworth/wiki/Troubleshooting)
can be found in the [Pennyworth Wiki](https://github.com/SUSE/pennyworth/wiki/).
