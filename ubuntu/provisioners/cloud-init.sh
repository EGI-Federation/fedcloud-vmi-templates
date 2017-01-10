#!/usr/bin/env bash

if [ "x$(lsb_release -rs)" == "x12.04" ]; then
  apt-get --assume-yes install python-software-properties
  add-apt-repository -y ppa:iweb-openstack/cloud-init
fi

apt-get -q update
apt-get -q --assume-yes install cloud-init curl

if [ "x$(lsb_release -rs)" == "x12.04" ]; then
  apt-get -q --assume-yes install cloud-utils-growpart
fi

if [ "x$(lsb_release -rs)" == "x14.04" ]; then
  pushd /usr/lib/python2.7/dist-packages/cloudinit/distros/
  patch -p 1 <  /root/cloud-init.patch
  popd
  # Create .pyc files
  rm /usr/lib/python2.7/dist-packages/cloudinit/distros/__init__.pyc \
     /usr/lib/python2.7/dist-packages/cloudinit/distros/debian.pyc \
     /usr/lib/python2.7/dist-packages/cloudinit/distros/rhel.pyc \
     /usr/lib/python2.7/dist-packages/cloudinit/distros/sles.pyc
  python -c "import cloudinit.distros.debian; import cloudinit.distros.rhel; import cloudinit.distros.sles"
  rm /root/cloud-init.patch
fi

mv /root/fedcloud.cfg /etc/cloud/cloud.cfg.d/01_fedcloud.cfg
