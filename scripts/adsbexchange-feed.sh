#!/bin/sh

trap "kill 0" SIGINT
trap "kill -2 0" SIGTERM

SOURCE="--net-connector localhost,30005,beast_in"
TARGET="--net-connector feed.adsbexchange.com,"$SERVERPORT",beast_reduce_out"
NET_OPTIONS="--net-only --net --net-heartbeat 60 --net-ro-size 1280 --net-ro-interval 0.2 --net-ro-port 0 --net-sbs-port 0 --net-bi-port 0 --net-bo-port 0 --net-ri-port 0"

while sleep 5
do
	if ping -q -c 2 -W 5 feed.adsbexchange.com >/dev/null 2>&1
	then
		echo Connected to feed.adsbexchange.com:$SERVERPORT
		
		/usr/local/share/feed-adsbx --net --net-only --quiet \
		--net-beast-reduce-interval 0.5 \
		$SOURCE $TARGET $NET_OPTIONS
		
		#/usr/bin/socat -u TCP:$INPUT TCP:feed.adsbexchange.com:$SERVERPORT
		
		echo Disconnected, reconnecting in 30 seconds!
	else
		echo Unable to connect to feed.adsbexchange.com, trying again in 30 seconds!
	fi
    sleep 25
done
