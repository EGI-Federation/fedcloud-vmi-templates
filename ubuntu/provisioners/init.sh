#!/usr/bin/env bash

set -x

# update already installed packages
apt-get -q update
apt-get -q --assume-yes upgrade


# shutdown ssh so reboot works (ubuntu 16.04)
service ssh stop
sleep 10s 
# reboot so we have the working kernel updated
reboot -f

sleep 90s
