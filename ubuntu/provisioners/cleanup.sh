#!/bin/bash -x

# Clean up leftover build files
sudo rm -fr /home/*/{.ssh,.ansible,.cache}
sudo rm -fr /root/{.ssh,.ansible,.cache}
sudo rm -fr /root/'~'*
sudo rm -f /tmp/sbom.cdx.json
