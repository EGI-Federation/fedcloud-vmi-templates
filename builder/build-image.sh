#!/bin/bash
set -e

error_handler() {

    if [[ -s /var/tmp/egi/vm_image_id ]]; then
        IMAGE_ID=$(cat /var/tmp/egi/vm_image_id)
        builder/refresh.sh vo.access.egi.eu "$(cat /var/tmp/egi/.refresh_token)" tests
        OS_TOKEN="$(yq -r '.clouds.tests.auth.token' /etc/openstack/clouds.yaml)"
        # delete test VMI
        openstack --os-cloud tests --os-token "$OS_TOKEN" image delete "$IMAGE_ID"
    fi

    if [[ -s /var/tmp/egi/vm_infra_id ]] ; then
        IM_INFRA_ID=$(cat /var/tmp/egi/vm_infra_id)
        # delete test VM
        im_client.py destroy "$IM_INFRA_ID"
    fi

    echo "### BUILD-IMAGE: ERROR - line $1"
    shift
    echo " Exit status: $1"
    shift
    echo " Command: $*"

    LINE="$1"
    shift
    STATUS="$1"
    shift
    echo "### BUILD-RESULT: $(jq -cn --arg status "ERROR" \
            --arg line "$LINE" --arg status "$STATUS" \
            --arg command "$*" '$ARGS.named')"
}

trap 'error_handler ${LINENO} $? ${BASH_COMMAND}' ERR INT TERM

IMAGE="$1"
FEDCLOUD_SECRET_LOCKER="$2"
COMMIT_SHA="$3"
UPLOAD="$4"

# create a virtual env for fedcloudclient
python3 -m venv "$PWD/.venv"
export PATH="$PWD/.venv/bin:$PATH"
pip install -qqq fedcloudclient simplejson yq python-hcl2 IM-client

# work with IGTF certificates
# https://fedcloudclient.fedcloud.eu/install.html#installing-egi-core-trust-anchor-certificates
wget https://raw.githubusercontent.com/tdviet/python-requests-bundle-certs/main/scripts/install_certs.sh
bash install_certs.sh


# Get openstack ready
mkdir -p /etc/openstack/
cp builder/clouds.yaml /etc/openstack/clouds.yaml
TMP_SECRETS="$(mktemp)"
fedcloud secret get --locker-token "$FEDCLOUD_SECRET_LOCKER" \
        deploy -f json >"$TMP_SECRETS" && mv "$TMP_SECRETS" secrets.json

jq -r '.token' < secrets.json > .refresh_token

# monitor ourselves
systemctl start notify

# get packer
export PACKER_CONFIG_DIR="$PWD"
curl -fsSL https://apt.releases.hashicorp.com/gpg > /etc/apt/trusted.gpg.d/hashicorp.asc
apt-add-repository -y "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
apt-get -qq update && apt-get -qq install -y packer
packer plugins install github.com/hashicorp/qemu
packer plugins install github.com/hashicorp/ansible

QEMU_SOURCE_ID=$(hcl2tojson "$IMAGE" | jq -r '.source[0].qemu | keys[]')
VM_NAME=$(hcl2tojson "$IMAGE" \
	| jq -r '.source[0].qemu.'"$QEMU_SOURCE_ID"'.vm_name')
QCOW_FILE="$VM_NAME.qcow2"

# do the build
if tools/build.sh "$IMAGE"; then
    # compress the resulting image
    OUTPUT_DIR="$(dirname "$IMAGE")/output-$QEMU_SOURCE_ID"
    qemu-img convert -O qcow2 -c "$OUTPUT_DIR/$VM_NAME" "$OUTPUT_DIR/$QCOW_FILE"

    # test the resulting image
    # test step 1/2: upload VMI to cloud provider
    builder/refresh.sh vo.access.egi.eu "$(cat /var/tmp/egi/.refresh_token)" tests
    OS_TOKEN="$(yq -r '.clouds.tests.auth.token' /etc/openstack/clouds.yaml)"
    IMAGE_ID=$(openstack --os-cloud tests --os-token "$OS_TOKEN" \
                   image create --disk-format qcow2 --file "$OUTPUT_DIR/$QCOW_FILE" \
		   --tag "image-builder-action" \
                   --column id --format value "$VM_NAME")
    echo "$IMAGE_ID" > /var/tmp/egi/vm_image_id

    # test step 2/2: use IM-client to launch the test VM
    pushd builder
    sed -i -e "s/%TOKEN%/$(cat ../.oidc_token)/" auth.dat
    sed -i -e "s/%IMAGE%/$IMAGE_ID/" vm.yaml
    IM_VM=$(im_client.py create vm.yaml)
    IM_INFRA_ID=$(echo "$IM_VM" | awk '/ID/ {print $NF}')
    echo "$IM_INFRA_ID" > /var/tmp/egi/vm_infra_id
    im_client.py wait "$IM_INFRA_ID"
    # still getting: ssh: connect to host <> port 22: Connection refused, so waiting a bit more
    sleep 30
    # get SSH command to connect to the VM
    # do pay attention to the "1" parameter, it corresponds to the "show_only" flag
    SSH_CMD=$(im_client.py ssh "$IM_INFRA_ID" 1 | grep --invert-match 'im.egi.eu')
    # if the below works, the VM is up and running and responds to SSH
    $SSH_CMD hostname || echo "SSH failed, but keep running"
    # at this point we may want to run more sophisticated tests
    # delete test VM
    im_client.py destroy "$IM_INFRA_ID"
    # delete test VMI
    openstack --os-cloud tests --os-token "$OS_TOKEN" image delete "$IMAGE_ID"
    popd

    # All going well, upload the VMI in the registry
    # this should be done only if this is a push to main
    #if test "$UPLOAD" == "true"; then
    if true; then
	    echo "$UPLOAD"
	    builder/upload.sh "$IMAGE" "$COMMIT_SHA" "$(realpath secrets.json)"
    fi
    echo "### BUILD-RESULT: $(jq -cn --arg status "SUCCESS" \
            --arg qcow "$QCOW_FILE" '$ARGS.named')"
else
    echo "### BUILD-RESULT: $(jq -cn --arg status "ERROR" \
            --arg description "Packer build failed, check log" '$ARGS.named')"
fi

echo "### BUILD ENDED"
