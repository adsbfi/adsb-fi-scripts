#!/bin/bash
set -x

IPATH=/usr/local/share/adsbexchange

systemctl disable --now adsbexchange-mlat
systemctl disable --now adsbexchange-feed

rm -f /lib/systemd/system/adsbexchange-mlat.service
rm -f /lib/systemd/system/adsbexchange-feed.service

rm -rf "$IPATH"

set +x

echo -----
echo "adsbexchange feed scripts have been uninstalled!"
