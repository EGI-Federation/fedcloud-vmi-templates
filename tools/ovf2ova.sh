#!/bin/bash

# simple script to create an OVA from OVF + disk
# input parameter: OVF file
# assumes disk is called: <ovfname>-disk1.vmdk 

OVF_FILE=$1

if [ "x$OVF_FILE" = "x" ]; then
    echo "missing parameter (ovf file)"
    exit 1
fi

WORKDIR=`dirname "$OVF_FILE"`
OVF_BASENAME=$(basename "$OVF_FILE")

OVA_NAME="${OVF_BASENAME%.*}"
DISK_NAME="${OVA_NAME}-disk1.vmdk"
DISK_FILE="$WORKDIR/${DISK_NAME}"

# this is to make it work in OS X
MF_DIR=`mktemp -d -t ovf2ova_XXXXXXXX`

pushd $WORKDIR
openssl sha1 *.vmdk *.ovf > $MF_DIR/$OVA_NAME.mf
popd

# create OVA
tar -cf "$OVA_NAME.ova" -C "$WORKDIR" "$OVA_NAME.ovf" "$DISK_NAME" -C "$MF_DIR" "$OVA_NAME.mf"

rm -rf "$MF_DIR"
