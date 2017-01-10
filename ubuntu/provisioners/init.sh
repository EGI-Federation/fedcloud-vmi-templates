#!/usr/bin/env bash

set -x

# update already installed packages
apt-get -q update
apt-get -q --assume-yes upgrade


# reboot so we have the working kernel updated
# shutdown ssh so reboot works (ubuntu 16.04)
release=$(lsb_release -r -s)
[[ $release =~ ^16 ]] && (service ssh stop && sleep 10s && reboot -f) || reboot

sleep 90s
