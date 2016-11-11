#!/usr/bin/env bash

# update already installed packages
apt-get -q update
apt-get -q --assume-yes upgrade

# reboot so we have the working kernel updated
reboot
sleep 90s
