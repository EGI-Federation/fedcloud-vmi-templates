#!/bin/bash
set -e

error_handler() {
    echo " Error in line: $1 " >> /var/log/image-build.log 2>&1
    shift
    echo " Exit status: $1 " >> /var/log/image-build.log 2>&1
    shift
    echo " Command: $* " >> /var/log/image-build.log 2>&1
}

trap 'error_handler ${LINENO} $? ${BASH_COMMAND}' ERR INT TERM

IMAGE="$1"
FEDCLOUD_SECRET_LOCKER="$2"

# create a virtual env for fedcloudclient
python3 -m venv "$PWD/.venv"
export PATH="$PWD/.venv/bin:$PATH"
pip install fedcloudclient simplejson yq python-hcl2

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
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo tee /etc/apt/trusted.gpg.d/hashicorp.asc
apt-add-repository -y "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
apt-get update && apt-get install -y packer
packer plugins install github.com/hashicorp/qemu
packer plugins install github.com/hashicorp/ansible

QEMU_SOURCE_ID=$(hcl2tojson "$IMAGE" | jq -r '.source[0].qemu | keys[]')
VM_NAME=$(hcl2tojson "$IMAGE" \
	| jq -r '.source[0].qemu.'"$QEMU_SOURCE_ID"'.vm_name')
QCOW_FILE="$VM_NAME.qcow2"

# Check if the image is already there
builder/refresh.sh vo.access.egi.eu "$(cat /var/tmp/egi/.refresh_token)" images
OS_TOKEN="$(yq -r '.clouds.images.auth.token' /etc/openstack/clouds.yaml)"
if openstack --os-cloud images --os-token "$OS_TOKEN" \
	object show egi_endorsed_vas \
	"$QCOW_FILE"  > /dev/null ; then
	# skip
	echo "Skipped build as image is already uploaded" >>/var/log/image-build.log
else
	# do the build
	{
		if tools/build.sh "$IMAGE"; then
			# refresh the token, it may have expired
    			OUTPUT_DIR="$(dirname "$IMAGE")/output-$QEMU_SOURCE_ID"
    			cd "$OUTPUT_DIR"
			# compress the resulting image
			qemu-img convert -O qcow2 -c "$VM_NAME" "$QCOW_FILE"
			builder/refresh.sh vo.access.egi.eu \
				"$(cat /var/tmp/egi/.refresh_token)" images
			OS_TOKEN="$(yq -r '.clouds.images.auth.token' \
				/etc/openstack/clouds.yaml)"
			openstack --os-cloud images --os-token "$OS_TOKEN" \
				object create egi_endorsed_vas \
				"$QCOW_FILE"
			SHA="$(sha512sum -z "$QCOW_FILE" | cut -f1 -d" ")"
			echo "SUCCESSFUL BUILD - $QCOW_FILE - $SHA"
		fi
	} >>/var/log/image-build.log 2>&1
fi

echo "BUILD ENDED" >>/var/log/image-build.log
