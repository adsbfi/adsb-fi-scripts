#!/bin/bash
set -x

IPATH=/usr/local/share/adsbfi

systemctl disable --now adsbfi-mlat
systemctl disable --now adsbfi-mlat2 &>/dev/null
systemctl disable --now adsbfi-feed

if [[ -d /usr/local/share/tar1090/html-adsbx ]]; then
    bash /usr/local/share/tar1090/uninstall.sh adsbx
fi

rm -f /lib/systemd/system/adsbfi-mlat.service
rm -f /lib/systemd/system/adsbfi-mlat2.service
rm -f /lib/systemd/system/adsbfi-feed.service

cp -f "$IPATH/adsbx-uuid" /tmp/adsbx-uuid
rm -rf "$IPATH"
mkdir -p "$IPATH"
mv -f /tmp/adsbx-uuid "$IPATH/adsbx-uuid"

set +x

echo -----
echo "adsbfi feed scripts have been uninstalled!"
