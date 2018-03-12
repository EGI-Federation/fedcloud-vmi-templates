#!/bin/bash

set -exuo pipefail

curl -L https://raw.githubusercontent.com/EGI-FCTF/fedcloud-userinterface/master/fedcloud-ui.sh > /tmp/fedcloud.ui

sed -i 's/# Some variables.*/set -exuo pipefail/' /tmp/fedcloud.ui

cat /tmp/fedcloud.ui | bash -
# this is here until I understand what's going on with the script
# cat /tmp/fedcloud.ui | bash -

rm -rf /tmp/fedcloud.ui

# prevent clock skew
apt-get install -y ntp
service ntp start

# Install VBoxGuestAdditions
apt-get install -y dkms

vbox_latest=$(curl http://download.virtualbox.org/virtualbox/LATEST.TXT)
curl http://download.virtualbox.org/virtualbox/$vbox_latest/VBoxGuestAdditions_$vbox_latest.iso > /tmp/vbox.iso
mount -o loop,ro /tmp/vbox.iso /mnt
pushd /mnt
# don't fail here
./VBoxLinuxAdditions.run || true
popd
umount /mnt
rm -rf /tmp/vbox.iso

# Create a ubuntu user and be sure that the password expires after login
cat > /etc/cloud/cloud.cfg.d/02_fedcloud_expire_password.cfg << EOF
# make ubuntu password expire
runcmd:
  - ["passwd", "-e", "ubuntu"]
EOF
