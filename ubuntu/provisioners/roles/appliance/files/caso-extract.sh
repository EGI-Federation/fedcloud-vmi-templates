#!/bin/sh

# shellcheck source=/dev/null
. /etc/egi/defaults

docker run -v /etc/caso/voms.json:/etc/caso/voms.json \
           -v /etc/caso/caso.conf:/etc/caso/caso.conf \
           -v /var/spool/caso:/var/spool/caso \
           -v /var/spool/apel:/var/spool/apel \
           --rm "$CASO_IMAGE"
