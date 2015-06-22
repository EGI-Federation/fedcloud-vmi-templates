#!/usr/bin/env bash

# update already installed packages
apt-get update

if [ "x$(lsb_release -rs)" == "x12.04" ]; then
  apt-get --assume-yes install python-software-properties
  add-apt-repository -y ppa:iweb-openstack/cloud-init
fi

apt-get update
apt-get --assume-yes upgrade
apt-get --assume-yes install cloud-init curl

# move configuration files to their right place
mv /root/sshd_config /etc/ssh/sshd_config
mv /root/cloud.cfg /etc/cloud/cloud.cfg

ln -s /dev/null /etc/udev/rules.d/75-persistent-net-generator.rules

# remove ssh keys
rm -f /etc/ssh/ssh_host_*

# lock root password
passwd -l root

# clean bash history and cloud init logs
rm -f ~/.bash_history
rm -f /var/log/cloud-init*

# Remove virtualbox things
rm -f VBoxGuestAdditions.iso
