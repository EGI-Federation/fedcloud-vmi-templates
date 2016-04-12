# Add fetch-crl to the rc.local
cat > /etc/rc.local << EOF
#!/bin/sh -e

[ -f /etc/default/fetch-crl ] && . /etc/default/fetch-crl
/usr/sbin/fetch-crl -q -p 2 &

exit 0
EOF


