#!/usr/bin/env bash

set -uexo pipefail

# update installation
yum -y update

# rebuild the initramfs for every kernel (allow partition grow)
for k in $(rpm -q kernel); do
    v=$(echo $k | cut -f2- -d-)
    echo "Rebuilding initramfs for kernel $v"
    dracut -f /boot/initramfs-${v}.img $v
done

reboot

sleep 90s
