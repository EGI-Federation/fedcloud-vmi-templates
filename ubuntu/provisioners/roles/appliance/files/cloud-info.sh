#!/bin/sh

# shellcheck source=/dev/null
. /etc/egi/defaults

docker run -v /etc/grid-security:/etc/grid-security \
	   -v /etc/cloud-info-provider/:/etc/cloud-info-provider/ \
	   --env-file /etc/cloud-info-provider/openstack.rc \
           --rm "$CLOUDINFO_IMAGE"

