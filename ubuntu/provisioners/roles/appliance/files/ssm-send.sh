#!/bin/sh

# shellcheck source=/dev/null
. /etc/egi/defaults

docker run -v /etc/grid-security:/etc/grid-security \
           -v /var/spool/apel:/var/spool/apel \
           -v /etc/apel:/etc/apel \
           --rm "$SSM_IMAGE" ssmsend
