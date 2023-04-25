#!/bin/bash

#####################################################################################
#                        adsb.fi SETUP SCRIPT                                #
#####################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#                                                                                   #
# Copyright (c) 2020 ADSBx                                                          #
#                                                                                   #
# Permission is hereby granted, free of charge, to any person obtaining a copy      #
# of this software and associated documentation files (the "Software"), to deal     #
# in the Software without restriction, including without limitation the rights      #
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell         #
# copies of the Software, and to permit persons to whom the Software is             #
# furnished to do so, subject to the following conditions:                          #
#                                                                                   #
# The above copyright notice and this permission notice shall be included in all    #
# copies or substantial portions of the Software.                                   #
#                                                                                   #
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR        #
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,          #
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE       #
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER            #
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,     #
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE     #
# SOFTWARE.                                                                         #
#                                                                                   #
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

set -e
trap 'echo "[ERROR] Error in line $LINENO when executing: $BASH_COMMAND"' ERR
renice 10 $$ &>/dev/null

IPATH=/usr/local/share/adsbfi

function abort() {
    echo ------------
    echo "Setup canceled (probably using Esc button)!"
    echo "Please re-run this setup if this wasn't your intention."
    echo ------------
    exit 1
}

## WHIPTAIL DIALOGS

BACKTITLETEXT="adsb.fi Setup Script"

whiptail --backtitle "$BACKTITLETEXT" --title "$BACKTITLETEXT" --yesno "Thanks for choosing to share your data with adsb.fi!\n\nadsb.fi is a co-op of ADS-B/Mode S/MLAT feeders from around the world. This script will configure your current ADS-B receiver to share your feeders data with adsb.fi.\n\nWould you like to continue setup?" 13 78 || abort

ADSBFIUSERNAME=$(whiptail --backtitle "$BACKTITLETEXT" --title "Feeder MLAT Name" --nocancel --inputbox "\nPlease enter a unique name to be shown on the MLAT map (the pin will be offset for privacy)\n\nExample: \"william34-london\", \"william34-jersey\", etc.\nDisable MLAT: enter a zero: 0" 12 78 3>&1 1>&2 2>&3) || abort

NOSPACENAME="$(echo -n -e "${ADSBFIUSERNAME}" | tr -c '[a-zA-Z0-9]_\- ' '_')"

if [[ "$NOSPACENAME" != 0 ]]; then
    whiptail --backtitle "$BACKTITLETEXT" --title "$BACKTITLETEXT" \
        --msgbox "For MLAT the precise location of your antenna is required.\
        \n\nA small error of 15m/45ft will cause issues with MLAT!\
        \n\nTo get your location, use any online map service or this website: https://www.mapcoordinates.net/en" 12 78 || abort
else
    whiptail --backtitle "$BACKTITLETEXT" --title "$BACKTITLETEXT" \
        --msgbox "MLAT DISABLED!.\
        \n\n For some local functions the approximate receiver location is still useful, it won't be sent to the server." 12 78 || abort
fi

#((-90 <= RECEIVERLATITUDE <= 90))
LAT_OK=0
until [ $LAT_OK -eq 1 ]; do
    RECEIVERLATITUDE=$(whiptail --backtitle "$BACKTITLETEXT" --title "Receiver Latitude ${RECEIVERLATITUDE}" --nocancel --inputbox "\nEnter your receivers precise latitude in degrees with 5 decimal places.\n(Example: 32.36291)" 12 78 3>&1 1>&2 2>&3) || abort
    LAT_OK=`awk -v LAT="$RECEIVERLATITUDE" 'BEGIN {printf (LAT<90 && LAT>-90 ? "1" : "0")}'`
done


#((-180<= RECEIVERLONGITUDE <= 180))
LON_OK=0
until [ $LON_OK -eq 1 ]; do
    RECEIVERLONGITUDE=$(whiptail --backtitle "$BACKTITLETEXT" --title "Receiver Longitude ${RECEIVERLONGITUDE}" --nocancel --inputbox "\nEnter your receivers longitude in degrees with 5 decimal places.\n(Example: -64.71492)" 12 78 3>&1 1>&2 2>&3) || abort
    LON_OK=`awk -v LON="$RECEIVERLONGITUDE" 'BEGIN {printf (LON<180 && LON>-180 ? "1" : "0")}'`
done

ALT=0
until [[ "$NOSPACENAME" == 0 ]] || [[ $ALT =~ ^(-?[0-9]*)ft$ ]] || [[ $ALT =~ ^(-?[0-9]*)m$ ]]; do
    ALT=$(whiptail --backtitle "$BACKTITLETEXT" --title "Altitude above sea level (at the antenna):" \
        --nocancel --inputbox \
"\nEnter your antennas altitude above sea level including the unit, no spaces:\n\n\
in feet like this:                   255ft\n\
or in meters like this:               78m\n" \
        12 78 3>&1 1>&2 2>&3) || abort
done

if [[ $ALT =~ ^-(.*)ft$ ]]; then
        NUM=${BASH_REMATCH[1]}
        NEW_ALT=`echo "$NUM" "3.28" | awk '{printf "-%0.2f", $1 / $2 }'`
        ALT=$NEW_ALT
fi
if [[ $ALT =~ ^-(.*)m$ ]]; then
        NEW_ALT="-${BASH_REMATCH[1]}"
        ALT=$NEW_ALT
fi

RECEIVERALTITUDE="$ALT"

#RECEIVERPORT=$(whiptail --backtitle "$BACKTITLETEXT" --title "Receiver Feed Port" --nocancel --inputbox "\nChange only if you were assigned a custom feed port.\nFor most all users it is required this port remain set to port 30005." 10 78 "30005" 3>&1 1>&2 2>&3)



INPUT="127.0.0.1:30005"
INPUT_TYPE="dump1090"

if [[ $(hostname) == "radarcape" ]] || pgrep rcd &>/dev/null; then
    INPUT="127.0.0.1:10003"
    INPUT_TYPE="radarcape_gps"
fi

tee /etc/default/adsbfi >/dev/null <<EOF
INPUT="$INPUT"
REDUCE_INTERVAL="0.5"

# feed name for checking MLAT sync 
# also displayed on the MLAT map
USER="$NOSPACENAME"

LATITUDE="$RECEIVERLATITUDE"
LONGITUDE="$RECEIVERLONGITUDE"

ALTITUDE="$RECEIVERALTITUDE"

# this is the source for 978 data, use port 30978 from dump978 --raw-port
# if you're not receiving 978, don't worry about it, not doing any harm!
UAT_INPUT="127.0.0.1:30978"

RESULTS="--results beast,connect,127.0.0.1:30104"
RESULTS2="--results basestation,listen,31009"
RESULTS3="--results beast,listen,30157"
RESULTS4="--results beast,connect,127.0.0.1:30169"
# add --privacy between the quotes below to disable having the feed name shown on the mlat map
# (position is never shown accurately no matter the settings)
PRIVACY=""
INPUT_TYPE="$INPUT_TYPE"

MLATSERVER="feed.adsb.fi:31090"
TARGET="--net-connector feed.adsb.fi,30004,beast_reduce_plus_out,feed.adsb.fi,64004"
NET_OPTIONS="--net-heartbeat 60 --net-ro-size 1280 --net-ro-interval 0.2 --net-ro-port 0 --net-sbs-port 0 --net-bi-port 30169 --net-bo-port 0 --net-ri-port 0 --write-json-every 1 --uuid-file /usr/local/share/adsbfi/adsbfi-uuid"
JSON_OPTIONS="--max-range 450 --json-location-accuracy 2 --range-outline-hours 24"
EOF

