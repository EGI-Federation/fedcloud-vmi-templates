#!/usr/bin/env bash

set -uexo pipefail

APPLIANCE_DIR=/tmp/fedcloudappliance
TAG=v0.3

# Get git repo to populate default config
git clone --branch $TAG https://github.com/enolfc/fedcloudappliance.git $APPLIANCE_DIR

mkdir -p /etc/cloudkeeper \
         /etc/cloudkeeper-os \
         /etc/apel \
         /etc/caso \
         /etc/cloud-info-provider \
         /etc/sitebdii \
         /var/spool/caso \
         /var/spool/apel \
         /image_data

pushd $APPLIANCE_DIR

# cloudkeeper-os
cp cloudkeeper/os/cloudkeeper-os.conf /etc/cloudkeeper-os/
cp cloudkeeper/os/voms.json  /etc/cloudkeeper-os/

cat > /etc/systemd/system/cloudkeeper-os.service << EOF
#
# This manages the cloudkeeper OS backend
#
[Unit]
Description=CloudKeeper Service
After=docker.service
Requires=docker.service

[Service]
ExecStartPre=-/usr/bin/docker stop cloudkeeper-os
ExecStartPre=-/usr/bin/docker rm -v cloudkeeper-os
ExecStart=/usr/bin/docker run --name cloudkeeper-os -v /etc/cloudkeeper-os/cloudkeeper-os.conf:/etc/cloudkeeper-os/cloudkeeper-os.conf -v /etc/cloudkeeper-os/voms.json:/etc/cloudkeeper-os/voms.json -v /image_data:/var/spool/cloudkeeper/images egifedcloud/cloudkeeper-os:$TAG
ExecStop=/usr/bin/docker stop cloudkeeper-os

[Install]
WantedBy=multi-user.target
EOF

# cloudkeeper core
cp cloudkeeper/core/image-lists.conf /etc/cloudkeeper
cp cloudkeeper/core/cloudkeeper.yml /etc/cloudkeeper

cat > /etc/cron.d/cloudkeeper << EOF
# Run cloudkeeper every 4 hours
26 */4 * * * root /usr/local/bin/cloudkeeper.sh >> /var/log/cloudkeeper.log 2>&1
EOF

cat > /usr/local/bin/cloudkeeper.sh << EOF
#!/bin/sh

docker run -v /etc/grid-security:/etc/grid-security \
           -v /etc/cloudkeeper:/etc/cloudkeeper \
           -v /image_data:/var/spool/cloudkeeper/images \
           --link cloudkeeper-os:backend \
           --rm egifedcloud/cloudkeeper:$TAG cloudkeeper sync --debug
EOF

# caso
cp accounting/caso/voms.json /etc/caso
cp accounting/caso/caso.conf /etc/caso

cat > /etc/cron.d/caso << EOF
# Run cASO every hour
14 * * * * root /usr/local/bin/caso-extract.sh >> /var/log/caso.log 2>&1
EOF

cat > /usr/local/bin/caso-extract.sh << EOF
#!/bin/sh

docker run -v /etc/caso/voms.json:/etc/caso/voms.json \
           -v /etc/caso/caso.conf:/etc/caso/caso.conf \
           -v /var/spool/caso:/var/spool/caso \
           -v /var/spool/apel:/var/spool/apel \
           --rm egifedcloud/caso:$TAG
EOF


# ssm
cp accounting/ssm/logging.cfg /etc/apel
cp accounting/ssm/sender.cfg /etc/apel

cat > /etc/cron.d/ssmsend << EOF
# Send SSM records every 6 hours
30 */6 * * * root /usr/local/bin/ssm-send.sh >> /var/log/ssm.log 2>&1
EOF

cat > /usr/local/bin/ssm-send.sh << EOF
#!/bin/sh

docker run -v /etc/grid-security:/etc/grid-security \
           -v /var/spool/apel:/var/spool/apel \
           --rm egifedcloud/ssm:$TAG ssmsend
EOF

# cloud-info
cp cloud-info/cloud/openstack.rc /etc/cloud-info-provider/
cp cloud-info/cloud/openstack.yaml /etc/cloud-info-provider/

# site-bdii
cat > /etc/sitebdii/docker-compose.yml << EOF
version: '2'
services:
  cloudbdii:
    image: egifedcloud/cloudbdii:$TAG
    volumes:
     - /etc/cloud-info-provider/openstack.rc:/etc/cloud-info-provider/openstack.rc
     - /etc/cloud-info-provider/openstack.yaml:/etc/cloud-info-provider/openstack.yaml
  sitebdii:
    image: egifedcloud/sitebdii:$TAG
    volumes:
     - /etc/sitebdii/site.cfg:/etc/glite-info-static/site/site.cfg
     - /etc/sitebdii/glite-info-site-defaults.conf:/etc/bdii/gip/glite-info-site-defaults.conf
    links:
     - cloudbdii
    ports:
     - "2170:2170"
EOF

cat > /etc/systemd/system/bdii.service << EOF
#
# This manages the docker-compose for BDII
#
[Unit]
Description=BDII Service
After=docker.service
Requires=docker.service

[Service]
ExecStartPre=/usr/local/bin/docker-compose -f /etc/sitebdii/docker-compose.yml rm -v -f -s
ExecStart=/usr/local/bin/docker-compose -f /etc/sitebdii/docker-compose.yml up
ExecStop=/usr/local/bin/docker-compose -f /etc/sitebdii/docker-compose.yml stop

[Install]
WantedBy=multi-user.target
EOF

cp cloud-info/site/site.cfg /etc/sitebdii/
cp cloud-info/site/glite-info-site-defaults.conf /etc/sitebdii/

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

IMAGES="cloudkeeper cloudkeeper-os bdii sitebdii cloudbdii caso ssm"
for i in $IMAGES; do
    docker pull egifedcloud/$i:$TAG
done

fetch-crl -p 2 -T 30 || true
