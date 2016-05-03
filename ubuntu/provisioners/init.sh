#!/usr/bin/env bash

# update already installed packages
apt-get update
apt-get --assume-yes upgrade

# move configuration files to their right place
mv /root/sshd_config /etc/ssh/sshd_config

# reboot so we have the working kernel updated
reboot
sleep 90s
