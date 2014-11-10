# Pennyworth -- Frontend for testing with virtual machines

## SYNOPSIS

`pennyworth` [options]

`pennyworth` help [command]


## DESCRIPTION

**Pennyworth** is a frontend for testing with virtual machines. It uses Vagrant
and libvirt to run virtual machines and helps with setting up and managing the
test environment based on this machines.


## GENERAL OPTIONS

  * `--version`:
    Give out version of pennyworth tool. Exit when done.

  * `--verbose`:
    Run in verbose mode.

  * `-d`,`--definitions-dir=DEFINITIONS_DIR`:
    Specify the path to the directory containing Veewee and Vagrant
    definitions. The directory needs to contain `veewee/` and `vagrant/`
    subdirectories. Default is `~/.pennyworth`.


## COMMANDS

### setup -- Prepare host machine for running virtual machines

`pennyworth` setup

Prepare host machine for running kvm and vagrant. This sets permissions and
starts required services. Some parts need root permissions.


### status -- Show status of virtual machines

`pennyworth` status

Show information about, if the system is set up, which base images are there,
which boxes are available, which machines are running, etc.


### build-base -- Build base images

`pennyworth` build-base <image_name>

Build all required base images. If a specific name is given, only build this
image.

### import-base -- Import base images

`pennyworth` import-base <image_name> [-u|--url]

Import all required base images, that were built on this machine. If a specific
name is given, only this image is imported. With the option url it is possible
to import the images from a web server.


### up -- Start virtual machine

`pennyworth` up <vm_name>

Start the virtual machine. If a specific name is given, only this machine will
be brought up.


### down -- Stop virtual machine

`pennyworth` down <vm_name>

Stop the virtual machine. If a specific name is given, only this machine will
be halted.


### list -- List virtual machines and base images

`pennyworth` list [-a|--all]

List information about available virtual machines and base images and some
related data like the list of ISO images used to build base images.


## FILES

  * `/tmp/pennyworth.log`:

    Pennyworth log.

## EXAMPLES

Start a virtual machine with the name "vm":

`pennyworth` up vm


## BUGS

If you find bugs please report them at
https://github.com/SUSE/pennyworth/issues/new.


## COPYRIGHT

Pennyworth is Copyright (c) 2013-2014 SUSE LLC
