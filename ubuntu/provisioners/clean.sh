#!/usr/bin/env bash

# Clean up
ln -s /dev/null /etc/udev/rules.d/75-persistent-net-generator.rules

# remove ssh keys
rm -f /etc/ssh/ssh_host_*
# use our ssh configuration
mv /root/sshd_config /etc/ssh/sshd_config


# lock root password
passwd -l root

# clean bash history and cloud init logs
rm -f ~/.bash_history
rm -f /var/log/cloud-init*

# Remove virtualbox things
rm -f VBoxGuestAdditions.iso
