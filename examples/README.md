# Pennyworth Examples

This directory contains an example base image definition and Vagrantfile in
order to demonstrate how a testing environment can be defined using pennyworth.
It provides a very basic openSUSE 13.1 machine.

## Base Image

The base image is defined in `examples/veewee/definitions/base_opensuse13.1_kvm`.
It can be build with:

`$ bin/pennyworth build-base -d examples/`

You can then import the resulting image into vagrant:

`$ bin/pennyworth import-base --local -d examples/`

## VM

At that point the 13.1 machine is ready to be used and can be started up like
this:

`$ bin/pennyworth up opensuse131 -d examples/`
