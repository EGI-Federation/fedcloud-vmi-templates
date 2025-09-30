#!/bin/bash
# Uploads an image to the registry
# First argument is the image description
# Second is the secrets file

set -e

IMAGE="$1"
COMMIT_SHA="$2"
IMAGE_TAG="$3"
SECRETS="$4"

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

# Now do the upload to registry
# tell oras that we have a home
# otherwise it will fail with
# Error: failed to get user home directory: $HOME is not defined
export HOME="$PWD"
jq -r '.registry_password' "$SECRETS" | \
        oras login -u "$(jq -r '.registry_user' "$SECRETS")"  \
        --password-stdin "$REGISTRY"

echo "## debugging"
echo "REPOSITORY: $REPOSITORY"
echo "VM_NAME: $VM_NAME"
echo "TAG: $TAG"
echo "QEMU_SOURCE_ID: $QEMU_SOURCE_ID"
echo "IMAGE: $IMAGE"
echo "QCOW_FILE: $QCOW_FILE"
echo "Metadata:"
jq . <metadata.json

oras push --annotation-file metadata.json \
	"$REGISTRY/$PROJECT/$REPOSITORY:$TAG" \
	"$QCOW_FILE:application/x-qemu-disk" || \
	oras push  "$REGISTRY/$PROJECT/$REPOSITORY:$TAG" \
	"$QCOW_FILE:application/x-qemu-disk"

popd

# SBOM
pushd "$(dirname "$IMAGE")"
SBOM_FILE="sbom.cdx.json"
if [ -f "$SBOM_FILE" ]; then
	oras attach --artifact-type application/vnd.cyclonedx+json \
	"$REGISTRY/$PROJECT/$REPOSITORY:$TAG" \
	"$SBOM_FILE"
fi

#
# Clean up old images, keep up to $KEEP_TAGS
#
# API call was crafted with the swagger UI
curl -X "GET" \
  -u "$(jq -r '.registry_user' "$SECRETS"):$(jq -r '.registry_password' "$SECRETS")" \
  "https://$REGISTRY/api/v2.0/projects/$PROJECT/respositories/$REPOSITORY/artifacts?with_tag=true" \
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
