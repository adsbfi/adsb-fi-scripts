#!/bin/bash

if grep -qs -e 'LATITUDE' /boot/adsb-config.txt &>/dev/null && [[ -f /boot/adsbx-env ]]; then
    source /boot/adsb-config.txt
    source /boot/adsbx-env
else
    source /etc/default/adsbfi
fi

if ! [[ -d /run/adsbfi-feed/ ]]; then
    mkdir -p /run/adsbfi-feed
fi

if [[ -z $INPUT ]]; then
    INPUT="127.0.0.1:30005"
fi

INPUT_IP=$(echo $INPUT | cut -d: -f1)
INPUT_PORT=$(echo $INPUT | cut -d: -f2)
SOURCE="--net-connector $INPUT_IP,$INPUT_PORT,beast_in,silent_fail"

if [[ -z $UAT_INPUT ]]; then
    UAT_INPUT="127.0.0.1:30978"
fi

UAT_IP=$(echo $UAT_INPUT | cut -d: -f1)
UAT_PORT=$(echo $UAT_INPUT | cut -d: -f2)
UAT_SOURCE="--net-connector $UAT_IP,$UAT_PORT,uat_in,silent_fail"


exec /usr/local/share/adsbfi/feed-adsbx --net --net-only --quiet \
    --write-json /run/adsbfi-feed \
    --net-beast-reduce-interval $REDUCE_INTERVAL \
    $TARGET $NET_OPTIONS \
    --lat "$LATITUDE" --lon "$LONGITUDE" \
    $UUID_FILE $JSON_OPTIONS \
    $UAT_SOURCE \
    $SOURCE \



