#!/usr/bin/env bash

# update already installed packages
apt-get update
apt-get --assume-yes upgrade

# reboot so we have the working kernel updated
reboot
sleep 90s
