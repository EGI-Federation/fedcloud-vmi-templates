#!/usr/bin/env bash

# Clean up
ln -s /dev/null /etc/udev/rules.d/75-persistent-net-generator.rules

# fix ssh configuration:
# 1. remove ssh keys
rm -f /etc/ssh/ssh_host_*
# 2. disable root login
sed -i 's/^PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
# 3. disable password authentication (cloud-init should also do this, but just in case)
sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config

# lock root password
passwd -l root

# clean bash history and cloud init logs
rm -f ~/.bash_history
rm -f /var/log/cloud-init*

# Remove virtualbox things
rm -f VBoxGuestAdditions.iso

# More cleanup
apt-get autoremove
rm -f /var/cache/apt/archives/*.deb /var/cache/apt/archives/partial/*.deb /var/cache/apt/*.bin || true

# fill with zeros
dd if=/dev/zero of=/bigemptyfile bs=4096k || echo "full disk"
rm -rf /bigemptyfile
