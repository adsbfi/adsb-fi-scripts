#!/bin/bash
set -x

IPATH=/usr/local/share/adsbexchange

systemctl disable --now adsbexchange-mlat
systemctl disable --now adsbexchange-mlat2 &>/dev/null
systemctl disable --now adsbexchange-feed

if [[ -d /usr/local/share/tar1090/html-adsbx ]]; then
    bash /usr/local/share/tar1090/uninstall.sh adsbx
fi

rm -f /lib/systemd/system/adsbexchange-mlat.service
rm -f /lib/systemd/system/adsbexchange-mlat2.service
rm -f /lib/systemd/system/adsbexchange-feed.service

cp -f "$IPATH/adsbx-uuid" /tmp/adsbx-uuid
rm -rf "$IPATH"
mkdir -p "$IPATH"
mv -f /tmp/adsbx-uuid "$IPATH/adsbx-uuid"

set +x

echo -----
echo "adsbexchange feed scripts have been uninstalled!"
