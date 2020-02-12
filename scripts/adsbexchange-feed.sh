#!/bin/sh

trap "kill 0" SIGINT
trap "kill -2 0" SIGTERM

while sleep 5
do
	if ping -q -c 2 -W 5 feed.adsbexchange.com >/dev/null 2>&1
	then
		echo Connected to feed.adsbexchange.com:$SERVERPORT
		/usr/local/bin/feed-adsbx
		#/usr/bin/socat -u TCP:$INPUT TCP:feed.adsbexchange.com:$SERVERPORT
		echo Disconnected, reconnecting in 30 seconds!
	else
		echo Unable to connect to feed.adsbexchange.com, trying again in 30 seconds!
	fi
    sleep 25
done
