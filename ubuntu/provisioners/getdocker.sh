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
apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 \
            --recv-keys 58118E89F3A912897C070ADBF76221572C52609D

add-apt-repository \
    "deb https://apt.dockerproject.org/repo/ ubuntu-$(lsb_release -cs)  main"

# and do the install
apt-get -q update

apt-get -q install -y docker-engine

# add docker-compose (1.10.0) to the image
curl -L https://github.com/docker/compose/releases/download/1.10.0/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

if [ "x$(lsb_release -cs)" = "xxenial" ]; then
    DOCKER_SERVICE=/lib/systemd/system/docker.service
    grep MountFlags $DOCKER_SERVICE \
        && sed -i 's/^MountFlags=shared/MountFlags=slave,shared/' $DOCKER_SERVICE \
        || sed -i '/^\[Service\]/a\
MountFlags=slave,shared
' $DOCKER_SERVICE
fi
