#!/bin/sh

. /etc/egi/defaults

docker run -v /etc/grid-security:/etc/grid-security \
           -v /etc/cloudkeeper:/etc/cloudkeeper \
           -v /var/lock/cloudkeeper:/var/lock/cloudkeeper \
           -v /etc/cloudkeeper/entrypoint.sh:/entrypoint.sh \
           -v /image_data:/var/spool/cloudkeeper/images \
           --link cloudkeeper-os:backend \
           --rm $CLOUDKEEPER_CORE_IMAGE cloudkeeper sync --debug

