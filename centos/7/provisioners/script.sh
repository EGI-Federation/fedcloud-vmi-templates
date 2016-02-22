#!/usr/bin/env bash

# add EPEL repository
yum -y install epel-release
# update already installed packages
yum -y update
# install new packages
yum -y install cloud-init

# rebuild the initramfs for every kernel
for k in $(rpm -q kernel); do
    v=$(echo $k | cut -f2- -d-)
    echo "Rebuilding initramfs for kernel $v"
    dracut -f -N /boot/initramfs-${v}.img $v
done

# set cloud-init to start after boot
systemctl enable cloud-init-local
systemctl enable cloud-init
systemctl enable cloud-config
systemctl enable cloud-final

# move configuration files to their right place
mv /root/sshd_config /etc/ssh/sshd_config
mv /root/cloud.cfg /etc/cloud/cloud.cfg

# remove ssh keys
rm -f /etc/ssh/ssh_host_*


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

rm /etc/udev/rules.d/80-net-name-slot.rules
ln -s /dev/null /etc/udev/rules.d/80-net-name-slot.rules 

rm /etc/udev/rules.d/80-net-setup-link.rules
ln -s /dev/null /etc/udev/rules.d/80-net-setup-link.rules

# remove hardware address (MAC) and UUID from NIC configuration files
sed -i '/^HWADDR/d' /etc/sysconfig/network-scripts/ifcfg-eth*
sed -i '/^UUID/d' /etc/sysconfig/network-scripts/ifcfg-eth*

# make sure nothing is messing with NICs' MAC adresses
unlink /etc/udev/rules.d/70-persistent-net.rules
ln -s /dev/null /etc/udev/rules.d/70-persistent-net.rules
unlink /etc/udev/rules.d/70-persistent-cd.rules
ln -s /dev/null /etc/udev/rules.d/70-persistent-cd.rules

# enable built-in networking
# using both commands because of unfinished systemd support in system
systemctl enable network
chkconfig network on

# disable NetworkManager
systemctl disable NetworkManager

# look root password
passwd -l root

# clean bash history and cloud init logs
rm -f ~/.bash_history
rm -f /var/log/cloud-init*
