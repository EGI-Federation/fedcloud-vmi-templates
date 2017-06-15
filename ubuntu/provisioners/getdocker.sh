#!/bin/sh -e

export DEBIAN_FRONTEND=noninteractive
apt-get update

# install dependencies
apt-get install -y apt-transport-https \
                   ca-certificates \
                   linux-image-extra-$(uname -r) \
                   apparmor
# this should be a noop, but just in case...
apt-get purge lxc-docker || true

# Add docker repo
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

# and do the install
apt-get -q update

apt-get -q install -y docker-ce

# add docker-compose (1.13.0) to the image
curl -L https://github.com/docker/compose/releases/download/1.13.0/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

if [ "x$(lsb_release -cs)" = "xxenial" ]; then
    DOCKER_SERVICE=/lib/systemd/system/docker.service
    grep MountFlags $DOCKER_SERVICE \
        && sed -i 's/^MountFlags=shared/MountFlags=slave,shared/' $DOCKER_SERVICE \
        || sed -i '/^\[Service\]/a\
MountFlags=slave,shared
' $DOCKER_SERVICE
fi
