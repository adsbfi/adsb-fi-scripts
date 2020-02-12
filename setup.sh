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

echo -e "\033[33m"
echo "Checking for packages needed to run this script..."

if [ $(dpkg-query -W -f='${STATUS}' curl 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
    echo "Installing the curl package..."
    echo -e "\033[37m"
    apt-get update
    apt-get install -y curl
fi
echo -e "\033[37m"

## ASSIGN VARIABLES

LOGDIRECTORY="$PWD/logs"
MLATCLIENTVERSION="0.2.10"
MLATCLIENTTAG="v0.2.10"

## WHIPTAIL DIALOGS

BACKTITLETEXT="ADS-B Exchange Setup Script"

whiptail --backtitle "$BACKTITLETEXT" --title "$BACKTITLETEXT" --yesno "Thanks for choosing to share your data with ADS-B Exchange!\n\nADSBexchange.com is a co-op of ADS-B/Mode S/MLAT feeders from around the world. This script will configure your current your ADS-B receiver to share your feeders data with ADS-B Exchange.\n\nWould you like to continue setup?" 13 78
CONTINUESETUP=$?
if [ $CONTINUESETUP = 1 ]; then
    exit 0
fi

ADSBEXCHANGEUSERNAME=$(whiptail --backtitle "$BACKTITLETEXT" --title "Feeder MLAT Name" --nocancel --inputbox "\nPlease enter a unique name for the feeder to be shown on the MLAT matrix (http://adsbx.org/sync)\n\nThis name MUST be unique, for this reason a random number is automatically added at the end.\nText and Numbers only - everything else will be removed.\nExample: \"william34-london\", \"william34-jersey\", etc." 12 78 3>&1 1>&2 2>&3)

whiptail --backtitle "$BACKTITLETEXT" --title "$BACKTITLETEXT" \
    --msgbox "For MLAT the precise location of your antenna is required.\
    \n\nA small error of 15m/45ft will cause issues with MLAT!\
    \n\nTo get your location, use any online map service or this website: https://www.mapcoordinates.net/en" 12 78

#((-90 <= RECEIVERLATITUDE <= 90))
LAT_OK=0
until [ $LAT_OK -eq 1 ]; do
    RECEIVERLATITUDE=$(whiptail --backtitle "$BACKTITLETEXT" --title "Receiver Latitude ${RECEIVERLATITUDE}" --nocancel --inputbox "\nEnter your receivers precise latitude in degrees with 5 decimal places.\n(Example: 32.36291)" 12 78 3>&1 1>&2 2>&3)
    LAT_OK=`awk -v LAT="$RECEIVERLATITUDE" 'BEGIN {printf (LAT<90 && LAT>-90 ? "1" : "0")}'`
done


#((-180<= RECEIVERLONGITUDE <= 180))
LON_OK=0
until [ $LON_OK -eq 1 ]; do
    RECEIVERLONGITUDE=$(whiptail --backtitle "$BACKTITLETEXT" --title "Receiver Longitude ${RECEIVERLONGITUDE}" --nocancel --inputbox "\nEnter your receivers longitude in degrees with 5 decimal places.\n(Example: -64.71492)" 12 78 3>&1 1>&2 2>&3)
    LON_OK=`awk -v LAT="$RECEIVERLONGITUDE" 'BEGIN {printf (LAT<180 && LAT>-180 ? "1" : "0")}'`
done

RECEIVERALTITUDE=$(whiptail --backtitle "$BACKTITLETEXT" --title "Altitude above sea level (at the antenna):" \
    --nocancel --inputbox "\nEnter your antennas altitude above sea level in feet like this:\n255ft\
    \nor in meters like this:\n78m\nNo Space between the number and unit!\n\
    (negative altitudes need to be entered in meters without a suffix)." 12 78 3>&1 1>&2 2>&3)

#RECEIVERPORT=$(whiptail --backtitle "$BACKTITLETEXT" --title "Receiver Feed Port" --nocancel --inputbox "\nChange only if you were assigned a custom feed port.\nFor most all users it is required this port remain set to port 30005." 10 78 "30005" 3>&1 1>&2 2>&3)


whiptail --backtitle "$BACKTITLETEXT" --title "$BACKTITLETEXT" --yesno "We are now ready to begin setting up your receiver to feed ADS-B Exchange.\n\nDo you wish to proceed?" 9 78
CONTINUESETUP=$?
if [ $CONTINUESETUP = 1 ]; then
    exit 0
fi

## BEGIN SETUP

{

    # Make a log directory if it does not already exist.
    if [ ! -d "$LOGDIRECTORY" ]; then
        mkdir $LOGDIRECTORY
    fi
    LOGFILE="$LOGDIRECTORY/image_setup-$(date +%F_%R)"
    touch $LOGFILE

    echo 4
    sleep 0.25

    # BUILD AND CONFIGURE THE MLAT-CLIENT PACKAGE

    echo "INSTALLING PREREQUISITE PACKAGES" >> $LOGFILE
    echo "--------------------------------------" >> $LOGFILE
    echo "" >> $LOGFILE


    # Check that the prerequisite packages needed to build and install mlat-client are installed.

	required_packages="build-essential debhelper python python3-dev socat ntp"
	progress=4

	for package in $required_packages
	do
		if [ $(dpkg-query -W -f='${STATUS}' $package 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
			apt-get install -y $package >> $LOGFILE  2>&1
		fi
		progress=$((progress+4))
		echo $progress
		sleep 0.25
	done

    echo "" >> $LOGFILE
    echo " BUILD AND INSTALL MLAT-CLIENT" >> $LOGFILE
    echo "-----------------------------------" >> $LOGFILE
    echo "" >> $LOGFILE

    CURRENT_DIR=$PWD

    # Check if the mlat-client git repository already exists.
    INSTALL_DIR=/usr/local/share/adsb-exchange
    MLAT_DIR=$INSTALL_DIR/mlat-client
    mkdir -p $INSTALL_DIR
    if [ -d $MLAT_DIR ] && [ -d $MLAT_DIR/.git ]; then
        # If the mlat-client repository exists update the source code contained within it.
        cd $MLAT_DIR >> $LOGFILE
        git fetch --depth 1 origin tag "$MLATCLIENTTAG" >> $LOGFILE 2>&1
        git reset --hard tags/$MLATCLIENTTAG >> $LOGFILE 2>&1
    else
        # Download a copy of the mlat-client repository since the repository does not exist locally.
        rm -rf $MLAT_DIR
        git clone -b $MLATCLIENTTAG --depth 1 https://github.com/adsbxchange/mlat-client.git $MLAT_DIR >> $LOGFILE 2>&1
        cd $MLAT_DIR >> $LOGFILE 2>&1
        git reset --hard tags/$MLATCLIENTTAG >> $LOGFILE 2>&1
    fi

    echo 34
    sleep 0.25

    # Build and install the mlat-client package.
    dpkg-buildpackage -b -uc >> $LOGFILE 2>&1

    echo 44

    cd .. >> $LOGFILE
    dpkg -i mlat-client_${MLATCLIENTVERSION}*.deb >> $LOGFILE 2>&1

    cd $CURRENT_DIR

    echo 54
    sleep 0.25

    echo "" >> $LOGFILE
    echo " CREATE AND CONFIGURE MLAT-CLIENT STARTUP SCRIPTS" >> $LOGFILE
    echo "------------------------------------------------------" >> $LOGFILE
    echo "" >> $LOGFILE
    
    NOSPACENAME="$(echo -e "${ADSBEXCHANGEUSERNAME}" | tr -dc '[a-zA-Z0-9]_\-')"

    # Remove old method of starting the feed script if present from rc.local
    sed -i -e '/adsbexchange-mlat_maint.sh/d' /etc/rc.local >> $LOGFILE 2>&1

    echo 58
    sleep 0.25


    # Kill the old adsbexchange-mlat_maint.sh script in case it's still running from a previous install
    pkill adsbexchange-mlat_maint.sh
    PIDS=`ps -efww | grep -w "adsbexchange-mlat_maint.sh" | awk -vpid=$$ '$2 != pid { print $2 }'`
    if [ ! -z "$PIDS" ]; then
        kill $PIDS >> $LOGFILE 2>&1
        kill -9 $PIDS >> $LOGFILE 2>&1
    fi

    echo 64
    sleep 0.25

    # copy adsbexchange-mlat service file
    cp $PWD/scripts/adsbexchange-mlat.service /lib/systemd/system >> $LOGFILE 2>&1

    # reload systemd daemons
    systemctl daemon-reload

    # Enable adsbexchange-mlat service
    systemctl enable adsbexchange-mlat >> $LOGFILE 2>&1

    echo 70
    sleep 0.25

    # SETUP FEEDER TO SEND DUMP1090 DATA TO ADS-B EXCHANGE

    echo "" >> $LOGFILE
    echo " CREATE AND CONFIGURE FEEDER STARTUP SCRIPTS" >> $LOGFILE
    echo "-------------------------------------------------" >> $LOGFILE
    echo "" >> $LOGFILE
    
    commands="git gcc make ld"
    packages="git build-essential"
    install=""

    for CMD in $commands; do
	if ! command -v "$CMD" &>/dev/null
	then
        install=1
	fi
    done

    if [[ -n "$install" ]]
    then
	echo "Installing required packages: $packages" >> $LOGFILE
	apt-get update || true
	if ! apt-get install -y $packages
	then
		echo "Failed to install required packages: $install" >> $LOGFILE
		echo "Exiting ..." >> $LOGFILE
		exit 1
	fi
	hash -r || true
    fi

    if ! [ -f /usr/local/share/feed-adsbx ]; then
	rm -rf /tmp/readsb &>/dev/null || true
	git clone --depth 1 https://github.com/adsbxchange/readsb.git /tmp/readsb
	cd /tmp/readsb
        apt install -y libncurses5-dev
	make
	cp readsb /usr/local/share/feed-adsbx
        cd /tmp
	rm -rf /tmp/readsb &>/dev/null || true
    fi
    
    mkdir -p /usr/local/bin
    cp $PWD/scripts/adsbexchange-feed.sh /usr/local/bin
    cp $PWD/scripts/adsbexchange-feed.service /lib/systemd/system

    tee /etc/default/adsbexchange > /dev/null <<EOF
    INPUT="127.0.0.1:30005"
    USER="${NOSPACENAME}_$((RANDOM % 90 + 10))"
    RECEIVERLATITUDE="$RECEIVERLATITUDE"
    RECEIVERLONGITUDE="$RECEIVERLONGITUDE"
    RECEIVERALTITUDE="$RECEIVERALTITUDE"
    RESULTS="--results beast,connect,localhost:30104 --results basestation,listen,31003"
    MLATSERVER="feed.adsbexchange.com:31090"
    INPUT_TYPE="dump1090"
    SERVERPORT="30005"
    SOURCE="--net-connector localhost,30005,beast_in"
    TARGET="--net-connector feed.adsbexchange.com,30005,beast_reduce_out"
    NET_OPTIONS="--net-only --net --net-heartbeat 60 --net-ro-size 1280 --net-ro-interval 0.2 --net-ro-port 0 --net-sbs-port 0 --net-bi-port 0 --net-bo-port 0 --net-ri-port 0"
EOF

    echo 76
    sleep 0.25

    # Set permissions on the file adsbexchange-feed.sh.
    chmod +x /usr/local/bin/adsbexchange-feed.sh >> $LOGFILE

    echo 82
    sleep 0.25

    # Remove old method of starting the feed script if present from rc.local
    sed -i -e '/adsbexchange-netcat_maint.sh/d' /etc/rc.local >> $LOGFILE 2>&1

    # Enable adsbexchange-feed service
    systemctl enable adsbexchange-feed  >> $LOGFILE 2>&1

    echo 88
    sleep 0.25

    # Kill the old adsbexchange-netcat_maint.sh script in case it's still running from a previous install
    pkill adsbexchange-netcat_maint.sh
    PIDS=`ps -efww | grep -w "adsbexchange-netcat_maint.sh" | awk -vpid=$$ '$2 != pid { print $2 }'`
    if [ ! -z "$PIDS" ]; then
        kill $PIDS >> $LOGFILE 2>&1
        kill -9 $PIDS >> $LOGFILE 2>&1
    fi

    echo 94
    sleep 0.25

    # make sure old feeds are no longer running ... this is a little brute force.
    pkill -f feed.adsbexchange.com:31090
    pkill -f feed.adsbexchange.com:30005

    # reload systemd daemons
    systemctl daemon-reload

    # Start or restart adsbexchange-feed service
    systemctl restart adsbexchange-feed  >> $LOGFILE 2>&1

    # Start or restart adsbexchange-mlat service
    systemctl restart adsbexchange-mlat >> $LOGFILE 2>&1

    echo 100
    sleep 0.25

} | whiptail --backtitle "$BACKTITLETEXT" --title "Setting Up ADS-B Exchange Feed"  --gauge "\nSetting up your receiver to feed ADS-B Exchange.\nThe setup process may take awhile to complete..." 8 60 0

## SETUP COMPLETE

# Display the thank you message box.
whiptail --title "ADS-B Exchange Setup Script" --msgbox "\nSetup is now complete.\n\nYou should now be feeding data to ADS-B Exchange. \nCheck here after 5 min: https://adsbexchange.com/myip/ http://adsbx.org/sync\nThanks again for choosing to share your data with ADS-B Exchange!\n\nIf you have questions or encountered any issues while using this script feel free to post them to one of the following places.\n\nhttp://www.adsbexchange.com/forums/topic/ads-b-exchange-setup-script/" 17 73

exit 0
