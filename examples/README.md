# Pennyworth Examples

This directory contains an example base image definition and Vagrantfile in
order to demonstrate how a testing environment can be defined using pennyworth.
It provides a very basic openSUSE Tumbleweed machine.

## Base Image

The base image is defined in `examples/boxes/definitions/opensuse_kvm`.
It can be build with:

`$ bin/pennyworth -d examples/ build-base`

You can then import the resulting image into vagrant:

`$ bin/pennyworth -d examples/ import-base`

## VM

At that point the openSUSE machine is ready to be used and can be started up like
this:

`$ bin/pennyworth -d examples/ up opensuse`
