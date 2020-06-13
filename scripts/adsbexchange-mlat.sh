#!/bin/bash

if [ -f /boot/adsb-config.txt ]; then
    source /boot/adsb-config.txt
    source /boot/adsbx-env
else
    source /etc/default/adsbexchange
fi

INPUT_IP=$(echo $INPUT | cut -d: -f1)
INPUT_PORT=$(echo $INPUT | cut -d: -f2)

while ! nc -z "$INPUT_IP" "$INPUT_PORT" && command -v nc &>/dev/null; do
    echo "<3>Could not connect to $INPUT_IP:$INPUT_PORT, retry in 30 seconds."
    sleep 30
done

/usr/local/share/adsbexchange/venv/bin/python3 /usr/local/share/adsbexchange/venv/bin/mlat-client \
	--input-type "$INPUT_TYPE" --no-udp \
	--input-connect "$INPUT" \
	--server "$MLATSERVER" \
	--user "$USER" \
	--lat "$LATITUDE" \
	--lon "$LONGITUDE" \
	--alt "$ALTITUDE" \
	$PRIVACY \
	$RESULTS $RESULTS1 $RESULTS2 $RESULTS3 $RESULTS4
