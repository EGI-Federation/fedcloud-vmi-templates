#!/usr/bin/env bash

set -x

# update already installed packages
apt-get -q update
apt-get -q --assume-yes upgrade


# reboot so we have the working kernel updated
# shutdown ssh so reboot works (ubuntu 16.04)
release=$(lsb_release -r -s)
if [[ $release =~ ^16 ]]; then
    #nohup (sleep 10s && shutdown --reboot now < /dev/null > /dev/null 2>&1) &
    #for dev in $(ifconfig -s | cut -f1  -d" " | grep -v Iface | grep -v lo); do
    #    ifconfig $dev down
    #    ifconfig $dev up
    #done

    (sleep 2s && shutdown --reboot now) &
    service ssh stop
else
    reboot
fi
