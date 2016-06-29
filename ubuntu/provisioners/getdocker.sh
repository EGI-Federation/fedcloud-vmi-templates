#!/bin/sh

export DEBIAN_FRONTEND=noninteractive
apt-get update

# install dependencies
apt-get install -y apt-transport-https \
                   ca-certificates \
                   linux-image-extra-$(uname -r) \
                   apparmor
# this should be a noop, but just in case...
apt-get purge lxc-docker

# Add docker repo
apt-key adv --keyserver hkp://p80.pool.sks-keyservers.net:80 \
            --recv-keys 58118E89F3A912897C070ADBF76221572C52609D

cat > /etc/apt/sources.list.d/docker.list << EOF
deb https://apt.dockerproject.org/repo ubuntu-trusty main
EOF

# and do the install
apt-get update

apt-get install -y docker-engine
