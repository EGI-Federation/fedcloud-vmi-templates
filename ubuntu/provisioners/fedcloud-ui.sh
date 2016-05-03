#!/bin/bash

curl -L https://raw.githubusercontent.com/EGI-FCTF/fedcloud-userinterface/master/fedcloud-ui.sh > /tmp/fedcloud.ui
cat /tmp/fedcloud.ui | bash -
# this is here until I understand what's going on with the script
cat /tmp/fedcloud.ui | bash -

rm -rf /tmp/fedcloud.ui

# Install VBoxGuestAdditions
apt-get update
apt-get install dkms

vbox_latest=$(curl http://download.virtualbox.org/virtualbox/LATEST.TXT)
curl http://download.virtualbox.org/virtualbox/$vbox_latest/VBoxGuestAdditions_$vbox_latest.iso > /tmp/vbox.iso
mount -o loop,ro /tmp/vbox.iso /mnt
pushd /mnt
./VBoxLinuxAdditions.run
popd
umount /mnt
rm -rf /tmp/vbox.iso
