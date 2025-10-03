#!/bin/bash
# Takes as argument the json file describing the build for packer
# e.g. build.sh centos-7.json
set -es nullglob

TEMPLATE_DIR="$(dirname "$1")"
pushd "$TEMPLATE_DIR"

TEMPLATE="$(basename "$1")"

# Create a temp ssh key that will be used to login to the VMs
SSH_KEY_DIR=$(mktemp -d)
ssh-keygen -f "$SSH_KEY_DIR/key" -N "" -t ed25519

# substitute SSH_KEY in any template
for tpl in httpdir/*.tpl; do
	dst="${tpl%.*}"
	sed "s#%SSH_KEY%#$(cat "$SSH_KEY_DIR/key.pub")#" "$tpl" > "$dst"
done

# build with this key
packer build -var "SSH_PRIVATE_KEY_FILE=$SSH_KEY_DIR/key" \
    -var "SSH_PUB_KEY=$(cat "$SSH_KEY_DIR/key.pub")" \
    "$TEMPLATE"

rm -rf "$SSH_KEY_DIR"
