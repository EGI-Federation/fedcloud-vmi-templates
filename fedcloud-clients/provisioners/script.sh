#!/usr/bin/env bash

# update already installed packages
apt-get update

if [ "x$(lsb_release -rs)" == "x12.04" ]; then
  apt-get --assume-yes install python-software-properties
  add-apt-repository -y ppa:iweb-openstack/cloud-init
fi

apt-get update
apt-get --assume-yes upgrade
apt-get --assume-yes install cloud-init

# move configuration files to their right place
mv /root/sshd_config /etc/ssh/sshd_config
mv /root/cloud.cfg /etc/cloud/cloud.cfg

ln -s /dev/null /etc/udev/rules.d/75-persistent-net-generator.rules

# remove ssh keys
rm -f /etc/ssh/ssh_host_*

# lock root password
passwd -l root

# install VOMS and rocci-cli
apt-get --assume-yes install curl libcommons-io-java

# UMD repo key
curl -s http://repository.egi.eu/sw/production/umd/UMD-DEB-PGP-KEY | \
        apt-key add -
# EUGridPMA repo key
curl -s https://dist.eugridpma.info/distribution/igtf/current/GPG-KEY-EUGridPMA-RPM-3 | \
        apt-key add -

# Repo configuration
curl -s http://repository.egi.eu/sw/production/cas/1/current/repo-files/egi-trustanchors.list -o /etc/apt/sources.list.d/egi-trustanchors.list

curl -s http://repository.egi.eu/sw/production/umd/3/repofiles/debian-squeeze/UMD-3-base.list -o /etc/apt/sources.list.d/UMD-3-base.list

curl -s http://repository.egi.eu/sw/production/umd/3/repofiles/debian-squeeze/UMD-3-updates.list -o /etc/apt/sources.list.d/UMD-3-updates.list

curl -s http://repository.egi.eu/community/software/rocci.cli/4.3.x/releases/repofiles/ubuntu-trusty-amd64.list -o /etc/apt/sources.list.d/rocci-cli.list

# prevent apt-get from trying to get i386 packages
dpkg --remove-architecture i386
# install
apt-get update
apt-get --assume-yes install ca-policy-egi-core fetch-crl occi-cli voms-clients3
# this is needed to make voms-clients work ?!
ln -s /usr/share/java/commons-io.jar /var/lib/voms-clients3/lib/

#
# configure VOMS
mkdir -p /etc/vomses
mkdir -p /etc/grid-security/vomsdir
mv /root/vomses/* /etc/vomses/
mv /root/vomsdir/* /etc/grid-security/vomsdir/

# Fetch CRLs so they are up to date
fetch-crl -v

# clean bash history and cloud init logs
rm -f ~/.bash_history
rm -f /var/log/cloud-init*

# Remove virtualbox things
rm -f VBoxGuestAdditions.iso
