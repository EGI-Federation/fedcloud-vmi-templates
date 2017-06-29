#!/bin/bash

set -uxeo pipefail

cat > /etc/sysconfig/network << EOF
NETWORKING=yes
NOZEROCONF=yes
EOF

# create ifcfg-eth0 conf
cat > /etc/sysconfig/network-scripts/ifcfg-eth0 << EOF
DEVICE="eth0"
BOOTPROTO="dhcp"
ONBOOT="yes"
TYPE="Ethernet"
USERCTL="yes"
PEERDNS="yes"
IPV6INIT="no"
PERSISTENT_DHCLIENT="1"
EOF

#rm /etc/udev/rules.d/80-net-name-slot.rules
#ln -s /dev/null /etc/udev/rules.d/80-net-name-slot.rules 

#rm /etc/udev/rules.d/80-net-setup-link.rules
#ln -s /dev/null /etc/udev/rules.d/80-net-setup-link.rules

# remove hardware address (MAC) and UUID from NIC configuration files
#sed -i '/^HWADDR/d' /etc/sysconfig/network-scripts/ifcfg-eth*
#sed -i '/^UUID/d' /etc/sysconfig/network-scripts/ifcfg-eth*

# make sure nothing is messing with NICs' MAC adresses
#unlink /etc/udev/rules.d/70-persistent-net.rules
#ln -s /dev/null /etc/udev/rules.d/70-persistent-net.rules
#unlink /etc/udev/rules.d/70-persistent-cd.rules
#ln -s /dev/null /etc/udev/rules.d/70-persistent-cd.rules

# enable built-in networking
# using both commands because of unfinished systemd support in system
systemctl enable network
chkconfig network on

# disable NetworkManager
systemctl disable NetworkManager
