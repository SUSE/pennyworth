#!/bin/bash
#======================================
# Functions...
#--------------------------------------
test -f /.kconfig && . /.kconfig
test -f /.profile && . /.profile

#======================================
# Greeting...
#--------------------------------------
echo "Configure image: [$kiwi_iname]..."

#======================================
# Mount system filesystems
#--------------------------------------
baseMount

#======================================
# Setup baseproduct link
#--------------------------------------
suseSetupProduct

#======================================
# Add missing gpg keys to rpm
#--------------------------------------
suseImportBuildKey

#======================================
# Activate services
#--------------------------------------
suseInsertService sshd

#======================================
# Setup default target, multi-user
#--------------------------------------
baseSetRunlevel 3

#======================================
# Vagrant
#--------------------------------------
date > /etc/vagrant_box_build_time
# set vagrant sudo
printf "%b" "
# added by veewee/postinstall.sh
vagrant ALL=(ALL) NOPASSWD: ALL
" >> /etc/sudoers

# speed-up remote logins
printf "%b" "
# added by veewee/postinstall.sh
UseDNS no
" >> /etc/ssh/sshd_config

chmod 600 /home/vagrant/.ssh/authorized_keys

#======================================
# Fixes for base images
#--------------------------------------
echo 'solver.allowVendorChange = true' >> /etc/zypp/zypp.conf
echo 'solver.onlyRequires = true' >> /etc/zypp/zypp.conf

# remove non-static files which break the tests on rebuilds
rm /var/log/YaST2/config_diff_*.log
rm /etc/zypp/repos.d/dir-*.repo

# create these files to prevent non-deterministic behavior on rebuilds or single inspections
touch /var/lib/zypp/AutoInstalled
touch /var/lib/zypp/LastDistributionFlavor

# Disable cron jobs in order to prevent created files breaking the tests
rm /etc/cron.daily/*

#======================================
# Repositories
#--------------------------------------
zypper --non-interactive --gpg-auto-import-keys refresh

#==========================================
# remove package docs
#------------------------------------------
rm -rf /usr/share/doc/packages/*
rm -rf /usr/share/doc/manual/*

#======================================
# Umount kernel filesystems
#--------------------------------------
baseCleanMount

exit 0
