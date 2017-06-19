#!/usr/bin/env bash

# add EPEL repository
yum -y install epel-release
# update already installed packages
yum -y update
# install new packages
yum -y install cloud-init cloud-utils-growpart dracut-modules-growroot patch parted

# rebuild the initramfs for every kernel (allow partition grow)
for k in $(rpm -q kernel); do
    v=$(echo $k | cut -f2- -d-)
    echo "Rebuilding initramfs for kernel $v"
    dracut -f /boot/initramfs-${v}.img $v
done

# fix cloud-init
pushd /usr/lib/python2.6/site-packages/cloudinit/sources
patch < /root/cloud-init.patch
rm /root/cloud-init.patch
popd
python -c "import cloudinit.sources.DataSourceOpenNebula"

# set cloud-init to start after boot
chkconfig cloud-init-local on
chkconfig cloud-init on
chkconfig cloud-config on
chkconfig cloud-final on

# move configuration files to their right place
mv /root/sshd_config /etc/ssh/sshd_config
mv /root/cloud.cfg /etc/cloud/cloud.cfg
mv /root/sudoers  /etc/sudoers

