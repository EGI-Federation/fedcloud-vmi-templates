#!/usr/bin/env bash

set -uxeo pipefail

# remove ssh keys
rm -f /etc/ssh/ssh_host_*

# remove hardware address (MAC) and UUID from NIC configuration files
sed -i '/^HWADDR/d' /etc/sysconfig/network-scripts/ifcfg-eth*
sed -i '/^UUID/d' /etc/sysconfig/network-scripts/ifcfg-eth*

# make sure nothing is messing with NICs' MAC adresses
unlink /etc/udev/rules.d/70-persistent-net.rules
ln -s /dev/null /etc/udev/rules.d/70-persistent-net.rules
unlink /etc/udev/rules.d/70-persistent-cd.rules
ln -s /dev/null /etc/udev/rules.d/70-persistent-cd.rules

chkconfig network on
echo "NOZEROCONF=yes" >> /etc/sysconfig/network

# look root password
passwd -l root

# clean bash history and cloud init logs
rm -f ~/.bash_history
rm -f /var/log/cloud-init*

# Remove virtualbox things
rm -f VBoxGuestAdditions.iso

# Fill in with zeros the space
dd if=/dev/zero of=/bigemptyfile bs=4096k || echo "full disk"
rm -rf /bigemptyfile
