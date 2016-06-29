#!/usr/bin/env bash

if [ "x$(lsb_release -rs)" == "x12.04" ]; then
  apt-get --assume-yes install python-software-properties
  add-apt-repository -y ppa:iweb-openstack/cloud-init
fi

apt-get update
apt-get --assume-yes install cloud-init curl

if [ "x$(lsb_release -rs)" == "x12.04" ]; then
  apt-get --assume-yes install cloud-utils-growpart
fi

mv /root/cloud.cfg /etc/cloud/cloud.cfg
