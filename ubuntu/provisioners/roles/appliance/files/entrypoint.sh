#!/bin/bash

if [ "$DEBUG" = "1" ] ; then
    set -x
fi

EXTRA_OPTS=()

if [ "$BACKEND_PORT_50051_TCP_ADDR" != "" ]; then
    EXTRA_OPTS=("${EXTRA_OPTS[@]}" --backend-endpoint="$BACKEND_PORT_50051_TCP_ADDR:$BACKEND_PORT_50051_TCP_PORT")
fi

exec "$@" "${EXTRA_OPTS[@]}"
