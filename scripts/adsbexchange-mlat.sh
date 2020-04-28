#!/bin/bash

if [ -f /boot/adsb-config.txt ]; then
    source /boot/adsb-config.txt
    source /boot/adsbx-env
else
    source /etc/default/adsbexchange
fi

INPUT_IP=$(echo $INPUT | cut -d: -f1)
INPUT_PORT=$(echo $INPUT | cut -d: -f2)
if ! nc -z "$INPUT_IP" "$INPUT_PORT"; then
    echo "<3>Could not connect to $INPUT_IP:$INPUT_PORT"
    exit 1
fi

/usr/local/share/adsbexchange/venv/bin/python3 /usr/local/share/adsbexchange/venv/bin/mlat-client \
	--input-type "$INPUT_TYPE" --no-udp \
	--input-connect "$INPUT" \
	--server "$MLATSERVER" \
	--user "$USER" \
	--lat "$LATITUDE" \
	--lon "$LONGITUDE" \
	--alt "$ALTITUDE" \
	$RESULTS $RESULTS1 $RESULTS2 $RESULTS3 $RESULTS4
