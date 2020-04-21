#!/bin/bash
/usr/local/share/adsbexchange/venv/bin/python3 /usr/local/share/adsbexchange/venv/bin/mlat-client \
	--input-type "$INPUT_TYPE" --no-udp \
	--input-connect "$INPUT" \
	--server "$MLATSERVER" \
	--user "$USER" \
	--lat "$RECEIVERLATITUDE" \
	--lon "$RECEIVERLONGITUDE" \
	--alt "$RECEIVERALTITUDE" \
	$RESULTS
