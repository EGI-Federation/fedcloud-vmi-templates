#!/bin/bash -x

# See https://github.com/NeCTAR-RC/nectar-images/blob/master/scripts/cleanup.sh

# Clean up leftover build files
rm -fr /home/*/{.ssh,.ansible,.cache}
rm -fr /root/{.ssh,.ansible,.cache}
rm -fr /root/'~'*
