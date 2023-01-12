#!/bin/bash

set -e

# Create a temp ssh key that will be used to login to the VMs
SSH_KEY_DIR=`mktemp -d`
ssh-keygen -f "$SSH_KEY_DIR/key" -N "" -t ed25519

# substitute SSH_KEY in any template
for tpl in httpdir/*.tpl; do
	dst="${tpl%.*}"
	sed "s#%SSH_KEY%#$(cat $SSH_KEY_DIR/key.pub)#" "$tpl" > "$dst"
done

# build with this key
packer build -var "SSH_PRIVATE_KEY_FILE=$SSH_KEY_DIR/key" \
    -var "SSH_PUB_KEY=$(cat $SSH_KEY_DIR/key.pub)" \
    "$1"

rm -rf "$SSH_KEY_DIR"

# convert to OVA
VM_NAME=$(jq -r ".builders[].vm_name" < "$1")

# Assume we are in the right location for the scripts to work
../tools/qcow2-to-ova.sh "$VM_NAME"
