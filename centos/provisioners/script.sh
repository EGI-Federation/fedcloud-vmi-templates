#!/usr/bin/env bash

# add EPEL repository
yum -y install epel-release
# install new packages
yum -y install cloud-init cloud-utils-growpart dracut-modules-growroot patch parted

# fix cloud-init
pushd /usr/lib/python2.6/site-packages/cloudinit/sources
patch < /root/cloud-init.patch
rm /root/cloud-init.patch
popd
python -c "import cloudinit.sources.DataSourceOpenNebula"
