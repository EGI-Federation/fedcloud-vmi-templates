#!/bin/bash

# Pre-requirements: gcc and linux-headers
apt-get install gcc linux-headers-$(uname -r)


CUDA_DEB=cuda-repo-ubuntu1404_7.5-18_amd64.deb

# Get CUDA repo package
curl -L http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1404/x86_64/$CUDA_DEB > $CUDA_DEB
dpkg -i $CUDA_DEB

# install...
apt-get update
apt-get --assume-yes install cuda 

