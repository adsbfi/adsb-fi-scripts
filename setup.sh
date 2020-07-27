#!/bin/bash

#####################################################################################
#                        ADS-B EXCHANGE SETUP SCRIPT FORKED                         #
#####################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#                                                                                   #
# Copyright (c) 2018 ADSBx                                    #
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

function abort() {
    echo ------------
    echo "Setup canceled (probably using Esc button)!"
    echo "Please re-run this setup if this wasn't your intention."
    echo ------------
    exit 1
}

## REFUSE INSTALLATION ON ADSBX IMAGE

if [ -f /boot/adsb-config.txt ]; then
    echo --------
    echo "You are using the adsbx image, the feed setup script does not need to be installed."
    echo "You should already be feeding, check here: https://adsbexchange.com/myip/"
    echo "If the feed isn't working, check/correct the configuration using nano:"
    echo --------
    echo "sudo nano /boot/adsb-config.txt"
    echo --------
    echo "Hint for using nano: Ctrl-X to exit, Y(yes) and Enter to save."
    echo --------
    echo "Exiting."
    exit 1
fi

## CHECK IF SCRIPT WAS RAN USING SUDO

if [ "$(id -u)" != "0" ]; then
    echo -e "\033[33m"
    echo "This script must be ran using sudo or as root."
    echo -e "\033[37m"
    exit 1
fi

## CHECK FOR PACKAGES NEEDED BY THIS SCRIPT

echo "Checking for packages needed to run this script..."

## ASSIGN VARIABLES

IPATH=/usr/local/share/adsbexchange
LOGDIRECTORY="$PWD/logs"

MLAT_VERSION="1296932bacb2b8ccbc4f8d6985755fe7436877f1"
READSB_VERSION="9cc3d6729a62c345e1a8ca335988a7c4db502a3f"

## WHIPTAIL DIALOGS

BACKTITLETEXT="ADS-B Exchange Setup Script"

whiptail --backtitle "$BACKTITLETEXT" --title "$BACKTITLETEXT" --yesno "Thanks for choosing to share your data with ADS-B Exchange!\n\nADSBexchange.com is a co-op of ADS-B/Mode S/MLAT feeders from around the world. This script will configure your current your ADS-B receiver to share your feeders data with ADS-B Exchange.\n\nWould you like to continue setup?" 13 78
if [[ $? != 0 ]]; then abort; fi

ADSBEXCHANGEUSERNAME=$(whiptail --backtitle "$BACKTITLETEXT" --title "Feeder MLAT Name" --nocancel --inputbox "\nPlease enter a unique name for the feeder to be shown on the MLAT matrix (http://adsbx.org/sync)\n\nThis name MUST be unique, for this reason a random number is automatically added at the end.\nText and Numbers only - everything else will be removed.\nExample: \"william34-london\", \"william34-jersey\", etc." 12 78 3>&1 1>&2 2>&3)

if [[ $? != 0 ]]; then abort; fi

whiptail --backtitle "$BACKTITLETEXT" --title "$BACKTITLETEXT" \
    --msgbox "For MLAT the precise location of your antenna is required.\
    \n\nA small error of 15m/45ft will cause issues with MLAT!\
    \n\nTo get your location, use any online map service or this website: https://www.mapcoordinates.net/en" 12 78

if [[ $? != 0 ]]; then abort; fi

#((-90 <= RECEIVERLATITUDE <= 90))
LAT_OK=0
until [ $LAT_OK -eq 1 ]; do
    RECEIVERLATITUDE=$(whiptail --backtitle "$BACKTITLETEXT" --title "Receiver Latitude ${RECEIVERLATITUDE}" --nocancel --inputbox "\nEnter your receivers precise latitude in degrees with 5 decimal places.\n(Example: 32.36291)" 12 78 3>&1 1>&2 2>&3)
    if [[ $? != 0 ]]; then abort; fi
    LAT_OK=`awk -v LAT="$RECEIVERLATITUDE" 'BEGIN {printf (LAT<90 && LAT>-90 ? "1" : "0")}'`
done


#((-180<= RECEIVERLONGITUDE <= 180))
LON_OK=0
until [ $LON_OK -eq 1 ]; do
    RECEIVERLONGITUDE=$(whiptail --backtitle "$BACKTITLETEXT" --title "Receiver Longitude ${RECEIVERLONGITUDE}" --nocancel --inputbox "\nEnter your receivers longitude in degrees with 5 decimal places.\n(Example: -64.71492)" 12 78 3>&1 1>&2 2>&3)
    if [[ $? != 0 ]]; then abort; fi
    LON_OK=`awk -v LAT="$RECEIVERLONGITUDE" 'BEGIN {printf (LAT<180 && LAT>-180 ? "1" : "0")}'`
done

until [[ $ALT =~ ^(.*)ft$ ]] || [[ $ALT =~ ^(.*)m$ ]]; do
    ALT=$(whiptail --backtitle "$BACKTITLETEXT" --title "Altitude above sea level (at the antenna):" \
        --nocancel --inputbox \
"\nEnter your receivers altitude above sea level including the unit:\n\n\
in feet like this:                   255ft\n\
or in meters like this:               78m\n" \
        12 78 3>&1 1>&2 2>&3)
    if [[ $? != 0 ]]; then abort; fi
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


whiptail --backtitle "$BACKTITLETEXT" --title "$BACKTITLETEXT" --yesno "We are now ready to begin setting up your receiver to feed ADS-B Exchange.\n\nDo you wish to proceed?" 9 78
CONTINUESETUP=$?
if [ $CONTINUESETUP = 1 ]; then
    exit 0
fi

## BEGIN SETUP

{

    # remove previously used folder to avoid confusion
    rm -rf /usr/local/share/adsb-exchange &>/dev/null

    # Make a log directory if it does not already exist.
    if [ ! -d "$LOGDIRECTORY" ]; then
        mkdir $LOGDIRECTORY
    fi
    LOGFILE="$LOGDIRECTORY/image_setup-$(date +%F_%R)"
    touch $LOGFILE

    mkdir -p $IPATH >> $LOGFILE  2>&1
    cp uninstall.sh $IPATH >> $LOGFILE  2>&1

    if ! id -u adsbexchange &>/dev/null
    then
        adduser --system --home $IPATH --no-create-home --quiet adsbexchange >> $LOGFILE  2>&1
    fi

    echo 4
    sleep 0.25

    # BUILD AND CONFIGURE THE MLAT-CLIENT PACKAGE

    echo "INSTALLING PREREQUISITE PACKAGES" >> $LOGFILE
    echo "--------------------------------------" >> $LOGFILE
    echo "" >> $LOGFILE


    # Check that the prerequisite packages needed to build and install mlat-client are installed.

    required_packages="git curl build-essential python3-dev socat ntp python3-venv libncurses5-dev netcat uuid-runtime"
    progress=4

    APT_UPDATED="false"

    for package in $required_packages
    do
        if [ $(dpkg-query -W -f='${STATUS}' $package 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
            if [[ "$APT_UPDATED" == "false" ]]; then
                apt-get update >> $LOGFILE 2>&1 && APT_UPDATED="true"
                if [[ "$APT_UPDATED" == "false" ]]; then
                    apt-get update >> $LOGFILE 2>&1 && APT_UPDATED="true"
                fi
            fi
            echo Installing $package >> $LOGFILE  2>&1
            # retry twice
            if ! apt-get install --no-install-recommends --no-install-suggests -y $package >> $LOGFILE  2>&1; then
                apt-get update >> $LOGFILE 2>&1 && APT_UPDATED="true"
                apt-get update >> $LOGFILE 2>&1 && APT_UPDATED="true"
                apt-get install --no-install-recommends --no-install-suggests -y $package >> $LOGFILE  2>&1
                apt-get install --no-install-recommends --no-install-suggests -y $package >> $LOGFILE  2>&1
            fi
        fi
        progress=$((progress+2))
        echo $progress
    done

    hash -r

    bash create-uuid.sh >> $LOGFILE  2>&1

    echo "" >> $LOGFILE
    echo " BUILD AND INSTALL MLAT-CLIENT" >> $LOGFILE
    echo "-----------------------------------" >> $LOGFILE
    echo "" >> $LOGFILE

    CURRENT_DIR=$PWD

    if ! grep -e "$MLAT_VERSION" -qs $IPATH/mlat_version
    then
        echo "Installing mlat-client to virtual environment" >> $LOGFILE
        # Check if the mlat-client git repository already exists.
        MLAT_DIR=$IPATH/mlat-git
        VENV=$IPATH/venv
        mkdir -p $IPATH >> $LOGFILE 2>&1
        if [ -d $MLAT_DIR ] && [ -d $MLAT_DIR/.git ]; then
            # If the mlat-client repository exists update the source code contained within it.
            cd $MLAT_DIR >> $LOGFILE
            git fetch >> $LOGFILE 2>&1
            git reset --hard origin/master >> $LOGFILE 2>&1
        else
            # Download a copy of the mlat-client repository since the repository does not exist locally.
            rm -rf $MLAT_DIR
            git clone https://github.com/adsbxchange/mlat-client.git $MLAT_DIR >> $LOGFILE 2>&1
            cd $MLAT_DIR >> $LOGFILE 2>&1
        fi

        echo 34
        sleep 0.25


        rm "$VENV" -rf
        /usr/bin/python3 -m venv $VENV 2>> $LOGFILE && echo 36 \
            && source $VENV/bin/activate 2>> $LOGFILE && echo 38 \
            && python3 setup.py build 2>> $LOGFILE && echo 40 \
            && python3 setup.py install 2>> $LOGFILE \
            && git rev-parse HEAD > $IPATH/mlat_version

    else
        echo "mlat-client already installed, git hash:" >> $LOGFILE
        cat $IPATH/mlat_version >> $LOGFILE
    fi

    echo 44

    cd $CURRENT_DIR

    sleep 0.25
    echo 54

    NOSPACENAME="$(echo -n -e "${ADSBEXCHANGEUSERNAME}" | tr -c '[a-zA-Z0-9]_\- ' '_')"

    # Remove old method of starting the feed script if present from rc.local
    if grep -qs -e 'adsbexchange-mlat_maint.sh' /etc/rc.local; then
        sed -i -e '/adsbexchange-mlat_maint.sh/d' /etc/rc.local >> $LOGFILE 2>&1
    fi

    # Kill the old adsbexchange-mlat_maint.sh script in case it's still running from a previous install
    pkill -f adsbexchange-mlat_maint.sh &>/dev/null
    PIDS=`ps -efww | grep -w "adsbexchange-mlat_maint.sh" | awk -vpid=$$ '$2 != pid { print $2 }'`
    if [ ! -z "$PIDS" ]; then
        kill $PIDS &>/dev/null
        kill -9 $PIDS &>/dev/null
    fi

    echo 64
    sleep 0.25

    # copy adsbexchange-mlat service file
    cp $PWD/scripts/adsbexchange-mlat.sh $IPATH >> $LOGFILE 2>&1
    cp $PWD/scripts/adsbexchange-mlat.service /lib/systemd/system >> $LOGFILE 2>&1

    # Enable adsbexchange-mlat service
    systemctl enable adsbexchange-mlat >> $LOGFILE 2>&1

    echo 70
    sleep 0.25

    # SETUP FEEDER TO SEND DUMP1090 DATA TO ADS-B EXCHANGE

    echo "" >> $LOGFILE
    echo " BUILD AND INSTALL FEED CLIENT" >> $LOGFILE
    echo "-------------------------------------------------" >> $LOGFILE
    echo "" >> $LOGFILE

    #save working dir to come back to it
    SCRIPT_DIR=$PWD

    if ! grep -e "$READSB_VERSION" -qs $IPATH/readsb_version
    then
        echo "Compiling / installing the readsb based feed client" >> $LOGFILE
        echo "" >> $LOGFILE

        #compile readsb
        echo 72

        rm -rf /tmp/readsb &>/dev/null || true
        git clone --depth 1 https://github.com/adsbxchange/readsb.git /tmp/readsb  >> $LOGFILE 2>&1
        cd /tmp/readsb
        echo 74
        if make -j3 2>> $LOGFILE >/dev/null
        then
            git rev-parse HEAD > $IPATH/readsb_version 2>> $LOGFILE
        fi

        mv $IPATH/feed-adsbx /tmp/old-feed-adsbx &>/dev/null
        cp readsb $IPATH/feed-adsbx >> $LOGFILE 2>&1
        rm -f /tmp/old-feed-adsbx &> /dev/null

        cd /tmp
        rm -rf /tmp/readsb &>/dev/null || true
        echo "" >> $LOGFILE
        echo "" >> $LOGFILE
    else
        echo "Feed client already installed, git hash:" >> $LOGFILE
        cat $IPATH/readsb_version >> $LOGFILE
    fi

    # back to the working dir for install script
    cd $SCRIPT_DIR
    #end compile readsb

    echo "" >> $LOGFILE
    echo "" >> $LOGFILE

    cp $PWD/scripts/adsbexchange-feed.sh $IPATH >> $LOGFILE 2>&1
    cp $PWD/scripts/adsbexchange-feed.service /lib/systemd/system >> $LOGFILE 2>&1

    tee /etc/default/adsbexchange > /dev/null 2>> $LOGFILE <<EOF
    INPUT="127.0.0.1:30005"
    REDUCE_INTERVAL="0.5"

    # feed name for checking MLAT sync (adsbx.org/sync)
    USER="${NOSPACENAME}_$((RANDOM % 90 + 10))"

    LATITUDE="$RECEIVERLATITUDE"
    LONGITUDE="$RECEIVERLONGITUDE"

    ALTITUDE="$RECEIVERALTITUDE"

    RESULTS="--results beast,connect,localhost:30104"
    RESULTS2="--results basestation,listen,31003"
    RESULTS3="--results beast,listen,30157"
    RESULTS4=""
    # add --privacy between the quotes below to disable having the feed name shown on the mlat map
    # (position is never shown accurately no matter the settings)
    PRIVACY=""
    INPUT_TYPE="dump1090"

    MLATSERVER="feed.adsbexchange.com:31090"
    TARGET="--net-connector feed.adsbexchange.com,30005,beast_reduce_out"
    NET_OPTIONS="--net-heartbeat 60 --net-ro-size 1280 --net-ro-interval 0.2 --net-ro-port 0 --net-sbs-port 0 --net-bi-port 30154 --net-bo-port 0 --net-ri-port 0"
EOF

    echo 82
    sleep 0.25

    # Remove old method of starting the feed script if present from rc.local
    if grep -qs -e 'adsbexchange-netcat_maint.sh' /etc/rc.local; then
        sed -i -e '/adsbexchange-netcat_maint.sh/d' /etc/rc.local >> $LOGFILE 2>&1
    fi

    # Enable adsbexchange-feed service
    systemctl enable adsbexchange-feed  >> $LOGFILE 2>&1

    echo 88
    sleep 0.25

    # Kill the old adsbexchange-netcat_maint.sh script in case it's still running from a previous install
    pkill -f adsbexchange-netcat_maint.sh &>/dev/null
    PIDS=`ps -efww | grep -w "adsbexchange-netcat_maint.sh" | awk -vpid=$$ '$2 != pid { print $2 }'`
    if [ ! -z "$PIDS" ]; then
        kill $PIDS &>/dev/null
        kill -9 $PIDS &>/dev/null
    fi

    echo 94
    sleep 0.25

    # Start or restart adsbexchange-feed service
    systemctl restart adsbexchange-feed  >> $LOGFILE 2>&1

    echo 96

    # Start or restart adsbexchange-mlat service
    systemctl restart adsbexchange-mlat >> $LOGFILE 2>&1

    echo 100
    sleep 0.25

    cp $LOGFILE $IPATH/lastlog &>/dev/null

} | whiptail --backtitle "$BACKTITLETEXT" --title "Setting Up ADS-B Exchange Feed"  --gauge "\nSetting up your receiver to feed ADS-B Exchange.\nThe setup process may take awhile to complete..." 8 60 0

## SETUP COMPLETE

ENDTEXT="
Setup is now complete.

You should now be feeding data to ADS-B Exchange.

Thanks again for choosing to share your data with ADS-B Exchange!

If you're curious, check your feed status after 5 min:

https://adsbexchange.com/myip/
http://adsbx.org/sync

If you have questions or encountered any issues while using this script feel free to post them to one of the following places:

http://www.adsbexchange.com/forums/topic/ads-b-exchange-setup-script/
https://discord.gg/ErEztqg
"


if ! nc -z 127.0.0.1 30005 && command -v nc &>/dev/null; then
    ENDTEXT2="
---------------------
No data available on port 30005!
---------------------
"
    if [ -f /etc/fr24feed.ini ] || [ -f /etc/rb24.ini ]; then
        ENDTEXT2+="
It looks like you are running FR24 or RB24
This means you will need to install a stand-alone decoder so data are avaible on port 30005!

We recommend using this script to install and configure a stand-alone decoder:

https://github.com/wiedehopf/adsb-scripts/wiki/readsb-script
---------------------
"
    else
        ENDTEXT2+="
If you have connected an SDR but not yet installed an ADS-B decoder for it,
we recommend this script:

https://github.com/wiedehopf/adsb-scripts/wiki/readsb-script
---------------------
"
    fi
    whiptail --title "ADS-B Exchange Setup Script" --msgbox "$ENDTEXT2" 24 73
    echo -e "$ENDTEXT2"
else
    # Display the thank you message box.
    whiptail --title "ADS-B Exchange Setup Script" --msgbox "$ENDTEXT" 24 73
    echo -e "$ENDTEXT"
fi


exit 0
