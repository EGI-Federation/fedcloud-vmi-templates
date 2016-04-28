#!/bin/sh

# install docker-compose
curl -L https://github.com/docker/compose/releases/download/1.6.2/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

mkdir /faafo
cd /faafo
git clone https://github.com/enolfc/faafo.git faafo
cd faafo
docker-compose pull
