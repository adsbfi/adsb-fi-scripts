#!/bin/bash

if [ -f /boot/adsb-config.txt ]; then
    source /boot/adsb-config.txt
    source /boot/adsbx-env
else
    source /etc/default/adsbexchange
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
