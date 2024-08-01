#!/bin/sh
set -e
set -x

IMAGE="$1"
FEDCLOUD_SECRET_LOCKER="$2"

# create a virtual env for fedcloudclient
python3 -m venv "$PWD/.venv"
PATH="$PWD/.venv/bin/pip:$PATH"
"$PWD/.venv/bin/pip" install fedcloudclient

mkdir -p /etc/openstack/
TMP_SECRETS="$(mktemp)"
fedcloud secret get --locker-token "$FEDCLOUD_SECRET_LOCKER" \
        deploy data >"$TMP_SECRETS" && mv "$TMP_SECRETS"  /etc/openstack/clouds.yaml

systemctl start notify

export PACKER_CONFIG_DIR="$PWD"

# get packer
curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add -
apt-add-repository -y "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
apt-get update && apt-get install -y packer
packer plugins install github.com/hashicorp/qemu
packer plugins install github.com/hashicorp/ansible

if tools/build.sh "$IMAGE" >/var/log/image-build.log 2>&1; then
	VM_NAME="$(jq -r ".builders[].vm_name" < "$IMAGE").ova"
	cd $(dirname "$IMAGE/output-qemu")
	openstack --os-cloud images \
		object create egi_endorsed_vas \
		"$VM_NAME" >>/var/log/image-build.log
	echo "SUCCESSFUL BUILD - uploaded $VM_NAME" >>/var/log/image-build.log
fi

echo "BUILD ENDED" >>/var/log/image-build.log
