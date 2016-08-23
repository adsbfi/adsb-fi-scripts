#!/bin/bash

#####################################################################################
#                        ADS-B EXCHANGE SETUP SCRIPT                                #
#####################################################################################
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
#                                                                                   #
# Copyright (c) 2015-2016 Joseph A. Prochazka                                       #
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


## CHECK IF SCRIPT WAS RAN USING SUDO


if [ "$(id -u)" != "0" ]; then
    echo "This script must be ran using sudo or as root."
    exit 1
fi


## ASSIGN VARIABLES


MLATCLIENTVERSION="0.2.6"
MLATCLIENTTAG="v0.2.6"


## WHIPTAIL DIALOGS


BACKTITLETEXT="ADS-B Exchange Setup Script"

whiptail --backtitle "$BACKTITLETEXT" --title "" --yesno "Thanks for choosing to share your data with ADS-B Exchange!\n\nADSBexchange.com is a co-op of ADS-B/Mode S/MLAT feeders from around the world. This script will configure your current your ADS-B receiver to share your feeders data with ADS-B Exchange.\n\nWould you like to continue setup?" 8 78
CONTINUESETUP=$?
if [ $CONTINUESETUP = 1 ]; then
    exit 0
fi

ADSBEXCHANGEUSERNAME=$(whiptail --backtitle "$BACKTITLETEXT" --title "ADS-B Exchange User Name" --inputbox "Please enter your ADS-B Exchange user name." 8 78 3>&1 1>&2 2>&3)

RECEIVERLONGITUDE=$(whiptail --backtitle "$BACKTITLETEXT" --title "Receiver Latitude" --inputbox "Enter your recivers latitude.." 8 78 3>&1 1>&2 2>&3)

RECEIVERLATITUDE=$(whiptail --backtitle "$BACKTITLETEXT" --title "Receiver Longitude" --inputbox "Enter your receivers longitude." 8 78 3>&1 1>&2 2>&3)


## BEGIN SETUP


{

    # BUILD AND CONFIGURE THE MLAT-CLIENT PACKAGE

    # Check that the prerequisite packages needed to build and install mlat-client are installed.
    if [ $(dpkg-query -W -f='$STATUS' build-essential 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
        sudo apt-get install -y build-essential
    fi

    if [ $(dpkg-query -W -f='$STATUS' debhelper 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
        sudo apt-get install -y debhelper
    fi

    if [ $(dpkg-query -W -f='$STATUS' python3-dev 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
        sudo apt-get install -y python3-dev
    fi

    # Check if the mlat-client git repository already exists.
    if [ -d mlat-client ] && [ -d mlat-client/.git ]; then
        # If the mlat-client repository exists update the source code contained within it.
        cd mlat-client
        git pull
        git checkout tags/$MLATCLIENTTAG
    else
        # Download a copy of the mlat-client repository since the repository does not exist locally.
        git clone https://github.com/mutability/mlat-client.git
        cd mlat-client
        git checkout tags/$MLATCLIENTTAG
    fi

    # Build and install the mlat-client package.
    dpkg-buildpackage -b -uc
    cd ..
    sudo dpkg -i mlat-client_${MLATCLIENTVERSION}*.deb

    # Create the mlat-client maintenance script.
    tee -a adsbexchange-mlat_maint.sh > /dev/null <<EOF
#!/bin/sh
while true
  do
    sleep 30
    /usr/bin/mlat-client --input-type dump1090 --input-connect localhost:30005 --lat $RECEIVERLATITUDE --lon $RECEIVERLONGITUDE --alt $RECEIVERLATITUDE --user $ADSBEXCHANGEUSERNAME --server feed.adsbexchange.com:31090 --no-udp --results beast,connect,localhost:30104
  done
EOF

    # Set execute permissions on the mlat-client maintenance script.
    chmod +x adsbexchange-mlat_maint.sh

    # Add a line to execute the mlat-client maintenance script to /etc/rc.local so it is started after each reboot if one does not already exist.
    if ! grep -Fxq "$PWD/adsbexchange-mlat_maint.sh &" /etc/rc.local; then
        LINENUMBER=($(sed -n '/exit 0/=' /etc/rc.local))
        ((LINENUMBER>0)) && sudo sed -i "${LINENUMBER[$((${#LINENUMBER[@]}-1))]}i $PWD/adsbexchange-mlat_maint.sh &\n" /etc/rc.local
    fi

    # Kill any currently running instances of the adsbexchange-mlat_maint.sh script.
    PIDS=`ps -efww | grep -w "adsbexchange-mlat_maint.sh" | awk -vpid=$$ '$2 != pid { print $2 }'`
    if [ ! -z "$PIDS" ]; then
        sudo kill $PIDS
        sudo kill -9 $PIDS
    fi

    # Execute the mlat-client maintenance script.
    sudo $PWD/adsbexchange-mlat_maint.sh > /dev/null &


    # SETUP NETCAT TO SEND DUMP1090 DATA TO ADS-B EXCHANGE


    # Check if netcat is installed and if not install it.
    if [ $(dpkg-query -W -f='${STATUS}' netcat 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
        sudo apt-get install -y netcat
    fi

    # Create the netcat maintenance script.
    tee -a adsbexchange-netcat_maint.sh > /dev/null <<EOF
#!/bin/sh
while true
  do
    sleep 30
    /bin/nc 127.0.0.1 30005 | /bin/nc feed.adsbexchange.com 30005
  done
EOF

    # Set permissions on the file adsbexchange-maint.sh.
    chmod +x adsbexchange-maint.sh

    # Add a line to execute the netcat maintenance script to /etc/rc.local so it is started after each reboot if one does not already exist.
    if ! grep -Fxq "${SCRIPTPATH}/adsbexchange-netcat_maint.sh &" /etc/rc.local; then
        lnum=($(sed -n '/exit 0/=' /etc/rc.local))
        ((lnum>0)) && sudo sed -i "${lnum[$((${#lnum[@]}-1))]}i ${SCRIPTPATH}/adsbexchange-maint.sh &\n" /etc/rc.local
    fi

    # Kill any currently running instances of the adsbexchange-netcat_maint.sh script.
    PIDS=`ps -efww | grep -w "adsbexchange-netcat_maint.sh" | awk -vpid=$$ '$2 != pid { print $2 }'`
    if [ ! -z "$PIDS" ]; then
        sudo kill $PIDS
        sudo kill -9 $PIDS
    fi

    # Execute the netcat maintenance script.
    sudo $PWD/adsbexchange-netcat_maint.sh > /dev/null &

} | whiptail --backtitle "$BACKTITLETEXT" --title "Setting up ADS-B Exchange Feed"  --gauge "Setting up your receiver to feed ADS-B Exchange..." 6 50 0


## SETUP COMPLETE


# Display the thank you message box.
whiptail --title "ADS-B Exchange Setup Script" --msgbox "Setup is now complete.\n\nYour feeder should now be feeding data to ADS-B Exchange.\nThanks again for choosing to share your data with ADS-B Exchange!\n\nIf you have questions or encountered any issues while using this script feel free to post them to one of the following places.\n\nhttps://github.com/jprochazka/adsb-exchange\nhttp://www.adsbexchange.com/forums/topic/ads-b-exchange-setup-script/" 16 73

exit 0
