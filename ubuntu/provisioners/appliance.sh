#!/usr/bin/env bash

set -uexo pipefail

APPLIANCE_DIR=/tmp/fedcloudappliance

# Get git repo and popoulate default config
git clone https://github.com/enolfc/fedcloudappliance.git $APPLIANCE_DIR

mkdir -p /etc/cloudkeeper \
         /etc/apel \
         /etc/caso \
         /etc/cloud-info-provider \
         /etc/sitebdii \
         /var/spool/caso \
         /var/spool/apel \
         /image_data

pushd $APPLIANCE_DIR

cp conf/voms.json /etc/
cp conf/cloudkeeper/cloudkeeper-os.conf conf/cloudkeeper/cloudkeeper.yml \
   conf/cloudkeeper/image-lists.conf \
   /etc/cloudkeeper/
cp conf/cloudkeeper/cloudkeeper-os.service /etc/systemd/system/
cp conf/caso/caso.conf /etc/caso
cp conf/cron.d/* /etc/cron.d
cp conf/bdii/openstack.rc /etc/cloud-info-provider/
cp conf/bdii/openstack.yaml /etc/cloud-info-provider/
cp conf/bdii/site.cfg /etc/sitebdii/
cp conf/bdii/glite-info-site-defaults.conf /etc/sitebdii/
cp conf/bdii/docker-compose.yml /etc/sitebdii/
cp conf/bdii/bdii.service /etc/systemd/system/ 
cp conf/scripts/* /usr/local/bin/

popd

chmod +x /usr/local/bin/*
systemctl enable bdii
systemctl enable cloudkeeper-os 

rm -rf $APPLIANCE_DIR

# Install CAs and fetch-crl
curl https://dist.eugridpma.info/distribution/igtf/current/GPG-KEY-EUGridPMA-RPM-3 | apt-key add - 
echo "deb http://repository.egi.eu/sw/production/cas/1/current egi-igtf core" >> /etc/apt/sources.list.d/egi-cas.list 
apt-get update
apt-get -qy install --fix-missing ca-policy-egi-core fetch-crl

fetch-crl || true 
