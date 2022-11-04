#!/bin/sh

# Converts the qcow2 image into a OVA for consumption in AppDB
NAME="$1"
QCOW2_FILE="output-qemu/$NAME"
VMDK_FILE="$NAME.vmdk"
OVA_FILE="$NAME.ova"

# First convert into vmdk
qemu-img convert -f qcow2 -O vmdk "$QCOW2_FILE" "$VMDK_FILE"

# Create one VM in Virtual Box that will be then exported to OVA
vboxmanage createvm --name="$NAME" --register
vboxmanage storagectl "$NAME" --add=ide --controller=PIIX4 --bootable=on --portcount=2 --name="IDE Controller"
vboxmanage storageattach "$NAME" --storagectl="IDE Controller"  --medium="$VMDK_FILE" --type=hdd --port=0 --device=0
vboxmanage modifyvm "$NAME" --memory 1024
vboxmanage export "$NAME" --output="$OVA_FILE" --ovf20

# we're done, remove them images
vboxmanage unregistervm "$NAME" --delete
rm "$VMDK_FILE"

echo "Converted image available at $OVA_FILE"
