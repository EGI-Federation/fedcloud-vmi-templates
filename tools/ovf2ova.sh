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

which sha1sum > /dev/null && SHASUMCMD=sha1sum || SHASUMCMD="shasum -a 1 -p"

echo "SHA1 ("$OVA_NAME.ovf")= `$SHASUMCMD "$OVF_FILE" | cut -f1 -d" "`" \ > "$MF_DIR/$OVA_NAME.mf"
echo "SHA1 ("$OVA_NAME-disk1.vmdk")= `$SHASUMCMD "$DISK_FILE" | cut -f1 -d" "`" \ >> "$MF_DIR/$OVA_NAME.mf"



# create OVA
tar -cf "$OVA_NAME.ova" -C "$WORKDIR" "$OVA_NAME.ovf" "$DISK_NAME" -C "$MF_DIR" "$OVA_NAME.mf"

rm -rf "$MF_DIR"
