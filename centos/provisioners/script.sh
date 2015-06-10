#!/usr/bin/env bash

# add EPEL repository
yum -y install epel-release
# update already installed packages
yum -y update
# install new packages
yum -y install cloud-init git

# set cloud-init to start after boot
systemctl enable cloud-init-local
systemctl enable cloud-init
systemctl enable cloud-config
systemctl enable cloud-final

# move configuration file to their right place
mv /root/sshd_config /etc/ssh/sshd_config
mv /root/cloud.cfg /etc/cloud/cloud.cfg

#mv /root/getty\@ttyS0.service /etc/systemd/system/getty\@ttyS0.service
#grub2-mkconfig -o /boot/grub2/grub.cfg
#ln -s /etc/systemd/system/getty\@ttyS0.service /etc/systemd/system/getty.target.wants/getty@ttyS0.service

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

# disable root login with password
passwd -d root

# clean bash history and cloud init logs
rm -f ~/.bash_history
rm -f /var/log/cloud-init*
