#!/bin/sh
set -e

IMAGE="$1"
FEDCLOUD_SECRET_LOCKER="$2"

# create a virtual env for fedcloudclient
python3 -m venv "$PWD/.venv"
export PATH="$PWD/.venv/bin:$PATH"
pip install fedcloudclient simplejson yq

# Get openstack ready
mkdir -p /etc/openstack/
cp builder/clouds.yaml /etc/openstack/clouds.yaml
TMP_SECRETS="$(mktemp)"
fedcloud secret get --locker-token "$FEDCLOUD_SECRET_LOCKER" \
        deploy data >"$TMP_SECRETS" && mv "$TMP_SECRETS"  .refresh_token

# monitor ourselves
systemctl start notify

# get packer
export PACKER_CONFIG_DIR="$PWD"
curl -fsSL https://apt.releases.hashicorp.com/gpg | apt-key add -
apt-add-repository -y "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
apt-get update && apt-get install -y packer
packer plugins install github.com/hashicorp/qemu
packer plugins install github.com/hashicorp/ansible

# do the build
if tools/build.sh "$IMAGE" >/var/log/image-build.log 2>&1; then
	builder/refresh.sh vo.access.egi.eu "$(cat /var/tmp/egi/.refresh_token)" images
	OS_TOKEN="$(yq -r '.clouds.images.auth.token' /etc/openstack/clouds.yaml)"
	VM_NAME="$(jq -r ".builders[].vm_name" < "$IMAGE")"
	cd "$(dirname "$IMAGE")/output-qemu"
	SHA="$(sha512sum -z "$VM_NAME" | cut -f1 -d" ")"
	openstack --os-cloud images --os-token "$OS_TOKEN" \
		object create egi_endorsed_vas \
		"$VM_NAME" >>/var/log/image-build.log
	echo "SUCCESSFUL BUILD - $VM_NAME - $SHA" >>/var/log/image-build.log
fi

echo "BUILD ENDED" >>/var/log/image-build.log
