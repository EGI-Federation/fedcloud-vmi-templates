#!/bin/bash

apt-get -y update

# some basic tools
apt-get install -y vim git

# Java env
apt-get install -y openjdk-7-jre openjdk-7-jre-lib openjdk-7-jdk maven
apt-get install ca-policy-egi-core
echo 'JAVA_HOME="/usr/lib/jvm/java-7-openjdk-amd64"' >> /etc/environment



# Python
apt-get -y install python-pip python-dev libffi-dev libssl-dev
pip install python-keystoneclient python-swiftclient \
            python-openstackclient PyOpenSSL xmltodict \
            openstack-voms-auth-type
# Add certificates to python requests
cat /etc/grid-security/certificates/*.pem >> $(python -m requests.certs)
