#!/bin/sh

# Install docker-compose
curl -L https://github.com/docker/compose/releases/download/1.6.2/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Get git repo and popoulate default config
git clone https://github.com/enolfc/fedcloudappliance.git /tmp/fedcloudappliance

mkdir -p /etc/atrope \
         /etc/apel \
         /etc/caso \
         /etc/cloud-info-provider \
         /etc/sitebdii \
         /var/spool/caso \
         /var/spool/apel \
         /image_data

cp /tmp/fedcloudappliance/conf/atrope/ /etc/atrope/
cp /tmp/fedcloudappliance/conf/atrope/* /etc/atrope/
cp /tmp/fedcloudappliance/conf/apel/* /etc/apel/
cp /tmp/fedcloudappliance/conf/caso/* /etc/caso
cp /tmp/fedcloudappliance/conf/voms.json /etc/
cp /tmp/fedcloudappliance/conf/cron.d/* /etc/cron.d
cp /tmp/fedcloudappliance/conf/bdii/openstack.rc /etc/cloud-info-provider/
cp /tmp/fedcloudappliance/conf/bdii/openstack.yaml /etc/cloud-info-provider/
cp /tmp/fedcloudappliance/conf/bdii/site.cfg /etc/sitebdii/
cp /tmp/fedcloudappliance/conf/bdii/glite-info-site-defaults.conf /etc/sitebdii/
cp /tmp/fedcloudappliance/conf/bdii/docker-compose.yml /etc/sitebdii/
cp /tmp/fedcloudappliance/conf/scripts/* /usr/local/bin/
chmod +x /usr/local/bin/*

rm -rf /tmp/fedcloudappliance

# Install CAs and fetch-crl
curl https://dist.eugridpma.info/distribution/igtf/current/GPG-KEY-EUGridPMA-RPM-3 | apt-key add - 
echo "deb http://repository.egi.eu/sw/production/cas/1/current egi-igtf core" >> /etc/apt/sources.list.d/egi-cas.list 
apt-get update
apt-get -qy install --fix-missing ca-policy-egi-core fetch-crl

fetch-crl || true 
