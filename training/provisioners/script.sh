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


# install and configure moin
DEBIAN_FRONTEND=noninteractive apt-get --assume-yes install python-moinmoin apache2 libapache2-mod-wsgi
mkdir -p /org/mywiki
cp -a  /usr/share/moin/data/ /org/mywiki/
cp -a /usr/share/moin/underlay /org/mywiki
chown -R www-data:www-data /org/mywiki
mv /root/mywiki.py /etc/moin/mywiki.py
a2enmod wsgi
mv /root/moin.conf /etc/apache2/conf-available/moin.conf
a2enconf moin
service apache restart

# clean bash history and cloud init logs
rm -f ~/.bash_history
rm -f /var/log/cloud-init*

# Remove virtualbox things
rm -f VBoxGuestAdditions.iso
