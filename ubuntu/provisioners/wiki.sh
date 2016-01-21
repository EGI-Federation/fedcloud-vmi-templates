#!/usr/bin/env bash

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
service apache2 restart
