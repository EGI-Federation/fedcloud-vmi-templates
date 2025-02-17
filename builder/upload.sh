#!/bin/bash
# Uploads an image to the registry
set -e

set -x

IMAGE="$1"
COMMIT_SHA="$2"
SECRETS="$3"

BASE_URL="https://github.com/EGI-Federation/fedcloud-vmi-templates"
REGISTRY="registry.egi.eu"
PROJECT="egi_vm_images"

# get oras
# See https://oras.land/docs/installation
VERSION="1.2.2"
curl -LO "https://github.com/oras-project/oras/releases/download/v${VERSION}/oras_${VERSION}_linux_amd64.tar.gz"
mkdir -p oras-install/
tar -zxf oras_${VERSION}_*.tar.gz -C oras-install/
export PATH="$PWD/oras-install:$PATH"

QEMU_SOURCE_ID=$(hcl2tojson "$IMAGE" | jq -r '.source[0].qemu | keys[]')
VM_NAME=$(hcl2tojson "$IMAGE" \
	| jq -r '.source[0].qemu.'"$QEMU_SOURCE_ID"'.vm_name')

REPOSITORY=$(echo "$VM_NAME" | cut -f1 -d"." | tr '[:upper:]' '[:lower:]')
TAG=$(echo "$VM_NAME" | cut -f2- -d".")

OUTPUT_DIR="$(dirname "$IMAGE")/output-$QEMU_SOURCE_ID"
QCOW_FILE="$OUTPUT_DIR/$VM_NAME.qcow2"

# these may be handy
ls -lh "$QCOW_FILE"
# SHA="$(sha512sum -z "$QCOW_FILE" | cut -f1 -d" ")"

MANIFEST_OUTPUT="$(dirname "$IMAGE")/$(hcl2tojson "$IMAGE" | \
        jq -r '.build[0]."post-processor"[0].manifest.output')"

# See annotation file format at:
# https://oras.land/docs/how_to_guides/manifest_annotations
jq -n --argjson "$(basename "$QCOW_FILE")" \
	"$(jq .builds[0].custom_data <"$MANIFEST_OUTPUT" | \
		jq '.+={"org.opencontainers.image.revision":"'"$COMMIT_SHA"'",
		        "org.opencontainers.image.source": "'"$BASE_URL"'"}')" \
	'$ARGS.named' >"$OUTPUT_DIR/annotation.json"
	
echo "annotation"
jq <"$OUTPUT_DIR/annotation.json"

# Now do the upload to registry
# tell oras that we have a home
# otherwise it will fail with
# Error: failed to get user home directory: $HOME is not defined
export HOME="$PWD"
jq -r '.registry_password' "$SECRETS" | \
        oras login -u "$(jq -r '.registry_user' "$SECRETS")"  \
        --password-stdin "$REGISTRY"
oras push --artifact-type application/application-x-qemu-disk \
	--annotation-file "$OUTPUT_DIR/annotation.json" \
        "$REGISTRY/$PROJECT/$REPOSITORY:$TAG" "$QCOW_FILE"
