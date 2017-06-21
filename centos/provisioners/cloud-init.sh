#!/usr/bin/env bash

set -uxeo pipefail

# add EPEL repository
yum -y install epel-release

CENTOS_RELEASE=$(cat /etc/redhat-release | grep -oP '(?<= )[0-9]+(?=\.)')

RPMS="cloud-init cloud-utils-growpart"
if [ "$CENTOS_RELEASE" = "6" ]; then
    RPMS="$RPMS dracut-modules-growroot patch parted"
fi

# install new packages
yum -y install $RPMS

# fix cloud-init (centos 6)
if [ "$CENTOS_RELEASE" = "6" ]; then
    pushd /usr/lib/python2.6/site-packages/cloudinit/sources
    patch < /root/cloud-init.patch
    rm /root/cloud-init.patch
    popd
    python -c "import cloudinit.sources.DataSourceOpenNebula"
fi

if [ "$CENTOS_RELEASE" = "7" ]; then
    # set cloud-init to start after boot
    systemctl enable cloud-init-local
    systemctl enable cloud-init
    systemctl enable cloud-config
    systemctl enable cloud-final
fi

# Use our config
mv /root/cloud.cfg /etc/cloud/cloud.cfg
