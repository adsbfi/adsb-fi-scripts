#!/bin/bash

#####################################################################################
#                        ADS-B EXCHANGE SETUP SCRIPT                                #
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

IPATH=/usr/local/share/adsbexchange

function abort() {
    echo ------------
    echo "Setup canceled (probably using Esc button)!"
    echo "Please re-run this setup if this wasn't your intention."
    echo ------------
    exit 1
}

## WHIPTAIL DIALOGS

BACKTITLETEXT="ADS-B Exchange Setup Script"

whiptail --backtitle "$BACKTITLETEXT" --title "$BACKTITLETEXT" --yesno "Thanks for choosing to share your data with ADS-B Exchange!\n\nADSBexchange.com is a co-op of ADS-B/Mode S/MLAT feeders from around the world. This script will configure your current your ADS-B receiver to share your feeders data with ADS-B Exchange.\n\nWould you like to continue setup?" 13 78 || abort

ADSBEXCHANGEUSERNAME=$(whiptail --backtitle "$BACKTITLETEXT" --title "Feeder MLAT Name" --nocancel --inputbox "\nPlease enter a unique name for the feeder to be shown on the MLAT matrix (http://adsbx.org/sync)\n\nText and Numbers only - everything else will be removed.\nExample: \"william34-london\", \"william34-jersey\", etc." 12 78 3>&1 1>&2 2>&3) || abort

NOSPACENAME="$(echo -n -e "${ADSBEXCHANGEUSERNAME}" | tr -c '[a-zA-Z0-9]_\- ' '_')"

whiptail --backtitle "$BACKTITLETEXT" --title "$BACKTITLETEXT" \
    --msgbox "For MLAT the precise location of your antenna is required.\
    \n\nA small error of 15m/45ft will cause issues with MLAT!\
    \n\nTo get your location, use any online map service or this website: https://www.mapcoordinates.net/en" 12 78 || abort

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
    LON_OK=`awk -v LAT="$RECEIVERLONGITUDE" 'BEGIN {printf (LAT<180 && LAT>-180 ? "1" : "0")}'`
done

until [[ $ALT =~ ^(.*)ft$ ]] || [[ $ALT =~ ^(.*)m$ ]]; do
    ALT=$(whiptail --backtitle "$BACKTITLETEXT" --title "Altitude above sea level (at the antenna):" \
        --nocancel --inputbox \
"\nEnter your receivers altitude above sea level including the unit:\n\n\
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



tee /etc/default/adsbexchange >/dev/null <<EOF
INPUT="127.0.0.1:30005"
REDUCE_INTERVAL="0.5"

# feed name for checking MLAT sync (adsbx.org/sync)
USER="$NOSPACENAME"

LATITUDE="$RECEIVERLATITUDE"
LONGITUDE="$RECEIVERLONGITUDE"

ALTITUDE="$RECEIVERALTITUDE"

RESULTS="--results beast,connect,localhost:30104"
RESULTS2="--results basestation,listen,31003"
RESULTS3="--results beast,listen,30157"
RESULTS4="--results beast,connect,localhost:30154"
# add --privacy between the quotes below to disable having the feed name shown on the mlat map
# (position is never shown accurately no matter the settings)
PRIVACY=""
INPUT_TYPE="dump1090"

MLATSERVER="feed.adsbexchange.com:31090"
TARGET="--net-connector feed.adsbexchange.com,30004,beast_reduce_out,feed.adsbexchange.com,64004"
NET_OPTIONS="--net-heartbeat 60 --net-ro-size 1280 --net-ro-interval 0.2 --net-ro-port 0 --net-sbs-port 0 --net-bi-port 30154 --net-bo-port 0 --net-ri-port 0 --write-json-every 5"
EOF

