#!/usr/bin/env bash

apt-get -y install git

curl -L https://github.com/docker/compose/releases/download/1.5.0/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

mkdir /faafo
pushd /faafo

git clone https://github.com/enolfc/faafo.git
pushd faafo
docker-compose pull 
