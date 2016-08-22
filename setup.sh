#!/bin/bash

# Check if user is using sudo or is logged in a root.
if [ "$(id -u)" != "0" ]; then
    echo "This script must be ran using sudo or as root."
    exit 1
fi

# Set a variable containing the path to this script.
SCRIPTPATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

##############
## FUNCTIONS

# Configure FlightAware's PiAware software.
function ConfigurePiAware() {
    # Retreive and clean the current PiAware mlatResultFormat setting.

    ORIGINALFORMAT="`sudo piaware-config -show mlat-results-format`"
    CLEANFORMAT=`sed 's/ beast,connect,feed.adsbexchange.com:30005//g' <<< $ORIGINALFORMAT`
    FINALFORMAT="${CLEANFORMAT} beast,connect,feed.adsbexchange.com:30005"

    for ((i = 0 ; i <= 33 ; i+=1)); do
        sleep 0.01
        echo $i
    done

    # Set the new PiAware mlatResultFormat setting.
    sudo piaware-config  mlat-results-format "${FINALFORMAT}"
    for ((i = 33 ; i <= 66 ; i+=1)); do
        sleep 0.01
        echo $i
    done

    # Restart PiAware.
    sudo piaware-config -restart &>/dev/null
    for ((i = 66 ; i <= 100 ; i+=1)); do
        sleep 0.01
        echo $i
    done

    sleep 2
}

# Setup the Netcat script and execute it.
function SetupNetcat() {
    # Check if netcat is installed and if not install it.
    if [ $(dpkg-query -W -f='${STATUS}' netcat 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
        sudo apt-get install netcat
    fi
    
    # Set permissions on the file adsbexchange-maint.sh.
    chmod 755 $SCRIPTPATH/adsbexchange-maint.sh
    for ((i = 0 ; i <= 20 ; i+=1)); do
        sleep 0.01
        echo $i
    done

    # Add the ADS-B maintainance script to the file /etc/rc.local.
    if ! grep -Fxq "${SCRIPTPATH}/adsbexchange-maint.sh &" /etc/rc.local; then
        lnum=($(sed -n '/exit 0/=' /etc/rc.local))
        ((lnum>0)) && sudo sed -i "${lnum[$((${#lnum[@]}-1))]}i ${SCRIPTPATH}/adsbexchange-maint.sh &\n" /etc/rc.local
    fi
    for ((i = 20 ; i <= 40 ; i+=1)); do
        sleep 0.01
        echo $i
    done

    # Kill any currently running instances of the adsbexchange-maint.sh script.
    PIDS=`ps -efww | grep -w "adsbexchange-maint.sh" | awk -vpid=$$ '$2 != pid { print $2 }'`
    if [ ! -z "$PIDS" ]; then
        sudo kill $PIDS
        for ((i = 40 ; i <= 90 ; i+=1)); do
            sleep 0.1
            echo $i
        done
        sudo kill -9 $PIDS
        echo 90
    else
        for ((i = 40 ; i <= 90 ; i+=1)); do
        sleep 0.1
        echo $i
        done
    fi

    # Execute the ADS-B maintainance script.

    # NOTE:
    # Executing the script here is causing display issues after the script completes.
    # For now I have moved the line which executes adsbexchange-maint.sh after the whiptail guage.

    #sudo $SCRIPTPATH/adsbexchange-maint.sh &
    for ((i = 90 ; i <= 100 ; i+=1)); do
        sleep 0.01
        echo $i
    done

    sleep 2
}

#############
## WHIPTAIL

# Welcome text.
read -d '' WELCOME <<"EOF"
Thanks for choosing to share your data with ADS-B Exchange!

ADSBexchange.com is a co-op of ADS-B/Mode S/MLAT feeders
from around the world. This script will configure your
current PiAware and/or Dump1090 installation to share
your feeders data with ADS-B Exchange. It is recommeded
that FlightAware's PiAware software be installed in order
to feed accurate "MLAT" data but is not required.

Would you like to continue setup?
EOF

# Display the welcome message box.
whiptail --title "ADS-B Exchange Setup Script" --yesno "$WELCOME" 16 65
CHOICE=$?

if [ $CHOICE = 1 ]; then
    exit 0
fi

# Check if the PiAware package is installed.
if [ $(dpkg-query -W -f='${STATUS}' $1 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
    # PiAware appear to be installed.
    ConfigurePiAware > >(whiptail --title "ADS-B Exchange Setup Script" --gauge "\nConfiguring PiAware to send MLAT data to ADS-B Exchange..." 7 65 0)
fi

# Setup the Netcat script.
SetupNetcat > >(whiptail --title "ADS-B Exchange Setup Script" --gauge "\nSetting up and executing the ADS-B Exchange Netcat script..." 7 65 0)
sudo $SCRIPTPATH/adsbexchange-maint.sh &

# Thank you text.
read -d '' THANKS <<"EOF"
Setup is now complete.

Your feeder should now be feeding data to ADS-B Exchange.
Thanks again for choosing to share your data with ADS-B Exchange!

If you have questions or encountered any issues while using this
script feel free to post them to one of the following places.

https://github.com/jprochazka/adsb-exchange
http://www.adsbexchange.com/forums/topic/ads-b-exchange-setup-script/
EOF

# Display the thank you message box.
whiptail --title "ADS-B Exchange Setup Script" --msgbox "$THANKS" 16 73

exit 0
