#!/usr/bin/env bash

set -uxeo pipefail

# remove ssh keys
rm -f /etc/ssh/ssh_host_*
# 2. disable root login
sed -i 's/^PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
# 3. disable password authentication (cloud-init should also do this, but just in case)
sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config

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
