#!/bin/bash
# Uploads an image to the registry
# Will not do the actual upload unless
# the first argument is "true"
#

set -e

DO_UPLOAD="$1"
IMAGE="$2"
COMMIT_SHA="$3"
IMAGE_TAG="$4"
SECRETS="$5"

# Configuration, this may be passed as input if needed
REGISTRY="registry.egi.eu"
PROJECT="egi_vm_images"
SOURCE_URL="https://github.com/EGI-Federation/fedcloud-vmi-templates"
KEEP_TAGS=4

# get oras
# See https://oras.land/docs/installation
ORAS_VERSION="1.2.2"
curl -LO "https://github.com/oras-project/oras/releases/download/v${ORAS_VERSION}/oras_${ORAS_VERSION}_linux_amd64.tar.gz"
mkdir -p oras-install/
tar -zxf oras_${ORAS_VERSION}_*.tar.gz -C oras-install/
export PATH="$PWD/oras-install:$PATH"

QEMU_SOURCE_ID=$(hcl2tojson "$IMAGE" | jq -r '.source[0].qemu | keys[]')
OUTPUT_DIR="$(dirname "$IMAGE")/output-$QEMU_SOURCE_ID"

MANIFEST_OUTPUT="$(dirname "$IMAGE")/$(hcl2tojson "$IMAGE" | \
        jq -r '.build[0]."post-processor"[0].manifest.output')"

VM_NAME=$(jq -r '.builds[0]["files"][0]["name"]' <"$MANIFEST_OUTPUT")
QCOW_FILE="$VM_NAME.qcow2"
REPOSITORY=$(echo "$VM_NAME" | cut -f1 -d"." | tr '[:upper:]' '[:lower:]')
OS_VERSION=$(jq -r '.builds[0].custom_data."org.openstack.glance.os_version"' < "$MANIFEST_OUTPUT")
LONG_TAG="$OS_VERSION-$IMAGE_TAG"
TAG="$LONG_TAG,$OS_VERSION"

# See annotation file format at:
# https://oras.land/docs/how_to_guides/manifest_annotations
jq -n --argjson '$manifest' \
        '{"org.opencontainers.image.revision":"'"$COMMIT_SHA"'",
          "org.opencontainers.image.source": "'"$SOURCE_URL"'"}' \
      --argjson "$QCOW_FILE" \
       "$(jq .builds[0].custom_data <"$MANIFEST_OUTPUT" | \
                jq '.+={"org.openstack.glance.disk_format": "qcow2",
                        "eu.egi.cloud.tag": "'"$IMAGE_TAG"'",
                        "org.openstack.glance.container_format": "bare"}')" \
       '$ARGS.named' >"$OUTPUT_DIR/metadata.json"

pushd "$OUTPUT_DIR"

echo "## debugging"
echo "DO_UPLOAD: $DO_UPLOAD"
echo "REPOSITORY: $REPOSITORY"
echo "VM_NAME: $VM_NAME"
echo "TAG: $TAG"
echo "QEMU_SOURCE_ID: $QEMU_SOURCE_ID"
echo "IMAGE: $IMAGE"
echo "QCOW_FILE: $QCOW_FILE"
echo "Metadata:"
jq . <metadata.json

# Now do the upload to registry
# tell oras that we have a home
# otherwise it will fail with
# Error: failed to get user home directory: $HOME is not defined
export HOME="$PWD"
if test "$DO_UPLOAD" == "true"; then
	jq -r '.registry_password' "$SECRETS" | \
		oras login -u "$(jq -r '.registry_user' "$SECRETS")"  \
		--password-stdin "$REGISTRY"

	oras push --annotation-file metadata.json \
		"$REGISTRY/$PROJECT/$REPOSITORY:$TAG" \
		"$QCOW_FILE:application/x-qemu-disk" || \
		oras push  "$REGISTRY/$PROJECT/$REPOSITORY:$TAG" \
		"$QCOW_FILE:application/x-qemu-disk"
else
	echo "Skipping upload of $QCOW_FILE to \
		$REGISTRY/$PROJECT/$REPOSITORY:$TAG"
fi

# SBOM Generation
# Get trivy
SBOM_FILE="sbom.cdx.json"
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key \
	| gpg --dearmor >  /usr/share/keyrings/trivy.gpg
echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] \
	https://aquasecurity.github.io/trivy-repo/deb generic main" \
	> /etc/apt/sources.list.d/trivy.list
apt-get update
apt-get install -y trivy
# Mount the qcow image
modprobe nbd max_part=8
# this needs to be running in the background
qemu-nbd -v --connect=/dev/nbd0 "$QCOW_FILE" &
# and it may not be immediate
sleep 3
# We assume the last partition is the good one
DEVICE=$(lsblk -l --json /dev/nbd0 \
	| jq -r .blockdevices[].name  | sort | tail -1)
mount "/dev/$DEVICE" /mnt
trivy rootfs \
	--quiet --scanners vuln --format cyclonedx --output "$SBOM_FILE" \
	/mnt
umount /mnt
qemu-nbd -d /dev/nbd0
if test "$DO_UPLOAD" == "true"; then
	oras attach --artifact-type application/vnd.cyclonedx+json \
	"$REGISTRY/$PROJECT/$REPOSITORY:$LONG_TAG" \
	"$SBOM_FILE"
else
	echo "Skipping upload of $SBOM_FILE as attachment to \
		$REGISTRY/$PROJECT/$REPOSITORY:$LONG_TAG"
fi

#
# Clean up old images, keep up to $KEEP_TAGS
#
if test "$DO_UPLOAD" == "true"; then
	# API call was crafted with the swagger UI
	curl -X "GET" \
	  -u "$(jq -r '.registry_user' "$SECRETS"):$(jq -r '.registry_password' "$SECRETS")" \
	  "https://$REGISTRY/api/v2.0/projects/$PROJECT/repositories/$REPOSITORY/artifacts?with_tag=true" \
	  -H 'accept: application/json' > images.json


	# Get those tags matching the OS_VERSION
	# Sort by pushtime, reverse and skip first $KEEP_TAGS
	# Then just take the tag names
	tags_to_delete=$(jq -r --arg version "$OS_VERSION" \
	  --argjson keep "$KEEP_TAGS" '
	  [.[] | select(.tags[]? | any(.name; startswith($version)))]
	  | sort_by(.push_time) | reverse | .[$keep:] | map(.tags[]|.name)| .[]' images.json)

	# Loop over the older tags
	for tag in $tags_to_delete; do
		echo "Deleting tag: $tag"
		oras delete "$REGISTRY/$PROJECT/$REPOSITORY:$tag"
	done
else
	echo "Skipping deletion of older images"
fi
