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

         $ git clone https://github.com/SUSE/pennyworth.git
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
[Kiwi](https://github.com/openSUSE/kiwi).

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

In your specs, you can now use the `start_system` method to start a VM, e.g.:

```ruby
describe "my pet feature" do
  it "works flawlessly" do
    vm = start_system(box: "box")

    # ...
  end
end
```

The `start_system` method can either start an existing Vagrant box, a generic
VM image runnable by libvirt or connect to an already running system. The method
returns an object, which can be used to access the system for testing.

#### Using Vagrant VMs

To start a Vagrant VM, pass its name using the `box` option. The name is looked
up in the `Vagrantfile` in the directory provided with the `config.vagrant_dir`
option in RSpec.

#### Using generic VM images

To start a generic VM image, pass its file path using the `image` option. The
image is ran in KVM and made available for accessing it for tests.

#### Using existing hosts

For connecting to an existing running system, pass the name of the system with
the `host` option. The name is looked up in a configuration file, which by
default is `~/.pennyworth/hosts.yaml`. The system is accessed with the address
stored in this file, so that the same name can be used in the tests, even when
the actual system used for tests is changing.

To prevent tests running simultaneously on the same machine to interfere with
each other, there is a locking mechanism, which automatically makes sure that
only one test is running on a system at the same time. For this to work a lock
service is required. The address of the lock service is also defined in the
`hosts.yaml` configuration file. The lock service has to conform to the API
implemented by [glockd](https://github.com/apokalyptik/glockd) and has to run
at the address specified in the configuration file.

To simplify setup of tests with existing hosts, there are some helper commands
in the pennyworth command line application. Get an overview by running
`pennyworth host`.

To initially set up the test infrastructure run

    pennyworth host setup http://ci.example.org

This will copy the `hosts.yaml` configuration file from
`http://ci.example.com/pennyworth/hosts.yaml` to your local configuration so
that it is picked up by Pennyworth automatically. This makes it easy to
distribute a common configuration between several systems and users.

Pennyworth automatically cleans up the hosts after running the tests using
snapper snapshots. The snapshot which the system is rolled back to is specified
by the `base_snapshot_id` of the host entries. Before rolling back a new
snapshot named `pennyworth` is created which can be used for debugging test
failures.

In some cases (e.g. while working on a test) the automatic rollback might not be
desired. It can easily be disabled temporarily by setting the `SKIP_CLEANUP`
environment variable, e.g.

    SKIP_CLEANUP=true rspec

An example for the configuration file is:

```yaml
---
lock_server_address: lockserver.example.org:9999
hosts:
  test_host_1:
    address: host1.example.org
    base_snapshot_id: 2
  test_host_2:
    address: host2.example.org
    base_snapshot_id: 34
```

In order to use a system as a pennyworth host it needs to be prepared like this:

  1. The root partition needs to be a Btrfs partition
  2. Snapper needs to be installed and configured for `/`:

       snapper create-config /

  3. There can't be any subvolumes below `/` besides `.snapshots`
  4. It's usually helpful to exclude `*/.ssh` from the rollback so that SSH
     access is retained

       echo "*/.ssh" > /etc/snapper/filters/ssh.txt

  5. There needs to be a snapper snapshot of the defined state which will be
     configured in the `hosts.yaml`:

       snapper create --description "Initial snapshot"

     The according snapshot id can be retrieved using

       snapper list

#### Accessing test systems

Boxes, images and systems have the following requirements:

  * ssh port is configured to be open in the firewall
  * activated sshd service
  * the public ssh key of the user running pennyworth/rspec tests in /root/.ssh.authorized_keys

For boxes handled by pennyworth the ssh key is copied into the target when creating the box,
for images or hosts this has to be done manually by e.g. running
`ssh-copy-id root@<HOST>`.

The `start_system` method returns a `VM` instance, which can be used to interact
with the running machine (via SSH). It supports the following methods:

  * `stop`

    Stops or disconnects the system. This stops running boxes or images and disconnects from
    running systems.

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
