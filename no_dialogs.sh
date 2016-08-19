#!/bin/bash

# Check if user is using sudo or is logged in a root.
if [ "$(id -u)" != "0" ]; then
    echo "This script must be ran using sudo or as root."
    exit 1
fi

clear

# Set a variable containing the path to this script.
SCRIPTPATH="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

##############
## FUNCTIONS

# Configure FlightAware's PiAware software.
function ConfigurePiAware() {
    # Retreive and clean the current PiAware mlatResultFormat setting.
    echo -e "\033[33m"
    echo "Adding the ADS-B Exchange feed to PiAware's configuration..."
    ORIGINALFORMAT="`sudo piaware-config -show mlat-results-format`"
    CLEANFORMAT=`sed 's/ beast,connect,feed.adsbexchange.com:30005//g' <<< $ORIGINALFORMAT`
    FINALFORMAT="${CLEANFORMAT} beast,connect,feed.adsbexchange.com:30005"

    # Set the new PiAware mlatResultFormat setting.
    sudo piaware-config  mlat-results-format "${FINALFORMAT}"

    # Restart PiAware.
    echo ""
    echo "Restarting PiAware so new configuration takes effect..."
    echo -e "\033[37m"
    sudo piaware-config -restart
}

# Setup the Netcat script and execute it.
function SetupNetcat() {
    # Set permissions on teh file adsbexchange-maint.sh.
    chmod 755 $SCRIPTPATH/adsbexchange-maint.sh

    # Add the ADS-B maintainance script to the file /etc/rc.local.
    if ! grep -Fxq "${SCRIPTPATH}/adsbexchange-maint.sh &" /etc/rc.local; then
        echo -e "\033[33m"
        echo "Adding ADS-B Exchange maintainance script startup command to rc.local..."
        echo -e "\033[37m"
        lnum=($(sed -n '/exit 0/=' /etc/rc.local))
        ((lnum>0)) && sudo sed -i "${lnum[$((${#lnum[@]}-1))]}i ${SCRIPTPATH}/adsbexchange-maint.sh &\n" /etc/rc.local
    fi

    # Kill any currently running instances of the adsbexchange-maint.sh script.
    echo -e "\033[33m"
    echo "Killing any adsbexchange-maint.sh processes currently running..."
    echo -e "\033[37m"
    PIDS=`ps -efww | grep -w "adsbexchange-maint.sh" | awk -vpid=$$ '$2 != pid { print $2 }'`
    if [ ! -z "$PIDS" ]; then
        sudo kill $PIDS
        sleep 5
        sudo kill -9 $PIDS
    fi

    # Execute the ADS-B maintainance script.
    echo -e "\033[33mRunning ADS-B Exchange maintainance script..."
    sudo $SCRIPTPATH/adsbexchange-maint.sh &
}

################
## NO WHIPTAIL

# Welcome message.
echo -e "\033[31m"
echo "-----------------------------------------------------------------"
echo " ADS-B Exchange Setup Script"
echo "-----------------------------------------------------------------"
echo -e "\033[33m"
echo "Thanks for choosing to share your data with ADS-B Exchange!"
echo ""
echo "ADSBexchange.com is a co-op of ADS-B/Mode S/MLAT feeders"
echo "from around the world. This script will configure your"
echo "current PiAware and/or Dump1090 installation to share"
echo "your feeders data with ADS-B Exchange. It is recommeded"
echo "that FlightAware's PiAware software be installed in order"
echo "to feed accurate \"MLAT\" data but is not required."
echo -e "\033[37m"
read -p "Continue setup? [Y/n] " CONTINUE

if [[ $CONTINUE == "" ]]; then CONTINUE="Y"; fi
if [[ ! $CONTINUE =~ ^[Yy]$ ]]; then
    echo ""
    exit 1
fi

# Check if the PiAware package is installed.
if [ $(dpkg-query -W -f='${STATUS}' $1 2>/dev/null | grep -c "ok installed") -eq 1 ]; then
    # PiAware appear to be installed.
    ConfigurePiAware
fi

# Setup the Netcat script.
SetupNetcat

# Thank you message.
echo -e "\033[33m"
echo "Setup is now complete."
echo ""
echo "Your feeder should now be feeding data to ADS-B Exchange."
echo "Thanks again for choosing to share your data with ADS-B Exchange!"
echo ""
echo "If you have questions or encountered any issues while using this"
echo "script feel free to post them to one of the following places."
echo ""
echo "https://github.com/jprochazka/adsb-exchange"
echo "http://www.adsbexchange.com/forums/topic/ads-b-exchange-setup-script/"
echo -e "\033[37m"

exit 0
