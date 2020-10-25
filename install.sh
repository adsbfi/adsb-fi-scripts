#!/bin/bash
TMP=/tmp/adsbexchange-git
if ! command -v git; then
    apt-get update
    apt-get install -y git
fi
rm -rf "$TMP"
set -e
git clone https://github.com/adsbxchange/adsb-exchange.git "$TMP"
cd "$TMP"
bash setup.sh
