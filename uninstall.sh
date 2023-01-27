#!/bin/bash
set -x

IPATH=/usr/local/share/adsbfi

systemctl disable --now adsbfi-mlat
systemctl disable --now adsbfi-mlat2 &>/dev/null
systemctl disable --now adsbfi-feed

if [[ -d /usr/local/share/tar1090/html-adsbfi ]]; then
    bash /usr/local/share/tar1090/uninstall.sh adsbfi
fi

rm -f /lib/systemd/system/adsbfi-mlat.service
rm -f /lib/systemd/system/adsbfi-mlat2.service
rm -f /lib/systemd/system/adsbfi-feed.service

cp -f "$IPATH/adsbfi-uuid" /tmp/adsbfi-uuid
rm -rf "$IPATH"
mkdir -p "$IPATH"
mv -f /tmp/adsbfi-uuid "$IPATH/adsbfi-uuid"

set +x

echo -----
echo "adsb.fi feed scripts have been uninstalled!"
