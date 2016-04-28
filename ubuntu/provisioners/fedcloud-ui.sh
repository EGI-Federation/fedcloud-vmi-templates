#!/bin/sh

curl -L http://go.egi.eu/fedcloud.ui > /tmp/fedcloud.ui
cat /tmp/fedcloud.ui | bash -
# this is here until I understand what's going on with the script
cat /tmp/fedcloud.ui | bash -

rm -rf /tmp/fedcloud.ui
