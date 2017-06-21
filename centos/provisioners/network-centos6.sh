#!/bin/bash

set -uxeo pipefail

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
echo "NETWORKING=yes" >> /etc/sysconfig/network
