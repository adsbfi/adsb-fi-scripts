#!/bin/bash
cat >/lib/systemd/system/adsbexchange-mlat2.service <<"EOF"
[Unit]
Description=adsbexchange-mlat2
Wants=network.target
After=network.target

[Service]
User=adsbexchange
EnvironmentFile=/etc/default/adsbexchange
ExecStart=/usr/local/share/adsbexchange/venv/bin/mlat-client \
    --input-type $INPUT_TYPE --no-udp \
    --input-connect $INPUT \
    --server feed.adsbexchange.com:SERVERPORT \
    --user $USER \
    --lat $LATITUDE \
    --lon $LONGITUDE \
    --alt $ALTITUDE \
    $PRIVACY \
    RESULTSLINE
Type=simple
Restart=always
RestartSec=30
StartLimitInterval=1
StartLimitBurst=100
SyslogIdentifier=adsbexchange-mlat2
Nice=-1

[Install]
WantedBy=default.target
EOF

sed -i -e "s/SERVERPORT/${1}/" /lib/systemd/system/adsbexchange-mlat2.service
sed -i -e "s/RESULTSLINE/${2}/" /lib/systemd/system/adsbexchange-mlat2.service

systemctl enable adsbexchange-mlat2
systemctl restart adsbexchange-mlat2
