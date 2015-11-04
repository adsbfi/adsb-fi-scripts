#!/bin/bash

clear

echo -e "\033[31m"
echo "-----------------------------------------------------"
echo " ADS-B Exchange Feeder Setup Script."
echo "-----------------------------------------------------"
echo -e "\033[33m"
echo "ADSBexchange.com is a co-op of ADS-B/Mode S/MLAT feeders from around the world."
echo "This script will setup your current PiAware installation to share your data with ADS-B Exchange as well."
echo "Please note that PiAware is required to be installed in order to feed ADS-B Exchange."
echo ""
echo "http://www.adsbexchange.com"
echo -e "\033[37m"
read -p "Continue setup? [Y/n] " CONTINUE

if [[ $CONTINUE == "" ]]; then CONTINUE="Y"; fi
if [[ ! $CONTINUE =~ ^[Yy]$ ]]; then
    echo ""
    exit 0
fi

## SPECIFY THE DIRECTORY TO PLACE ADS-B EXCHANGE MAINTAINANCE SCRIPT

echo -e "\033[33m"
echo "Please specify a directory in which to download the ADS-B Exchange maintainance script."
echo "This directory will be created for you if it does not already exist."
echo -e "\033[37m"

NOBUILDDIR="true"
while [[ $NOBUILDDIR == 'true' ]]
do
    read -p "Directory Path: [$PWD/adsb-exchange] " BUILDDIR
    if [[ $BUILDDIR == '' ]]; then
        BUILDDIR="$PWD/adsb-exchange"
    fi
    if [ ! -d "$BUILDDIR" ]; then
        echo ""
        mkdir -p $BUILDDIR
    fi
    if [ -d "$BUILDDIR" ]; then
        NOBUILDDIR="false"
    else
        echo "Please make sure the path specified is valid and you have permission to write to it."
        echo -e "\033[37m"
    fi
done

cd $BUILDDIR

## CONFIGURE PIAWARE TO FEED ADS-B EXCHANGE

echo -e "\033[33m"
echo "Adding the ADS-B Exchange feed to PiAware's configuration..."
echo -e "\033[37m"
MLATRESULTFORMAT=`sudo piaware-config -show | grep mlatResultsFormat`
ORIGINALFORMAT=`sed 's/mlatResultsFormat //g' <<< $MLATRESULTFORMAT`
CLEANFORMAT=`sed 's/ beast,connect,feed.adsbexchange.com:30005//g' <<< $ORIGINALFORMAT`
CLEANFORMAT=`sed 's/}//g' <<< $CLEANFORMAT`
CLEANFORMAT=`sed 's/{//g' <<< $CLEANFORMAT`
COMMAND=`sudo piaware-config -mlatResultsFormat "${CLEANFORMAT} beast,connect,feed.adsbexchange.com:30005"`
$COMMAND
sudo piaware-config -restart

## DOWNLOAD THE ADS-B EXCHANGE MAINTAINANCE SCRIPT

echo -e "\033[33m"
echo "Downloading ADS-B Exchange maintainance script..."
echo -e "\033[37m"
wget http://bucket.adsbexchange.com/adsbexchange-maint.sh -O $BUILDDIR/adsbexchange-maint.sh

## SET PERMISSIONS ON THE ADS-B EXCHANGE MAINTAINANCE SCRIPT

echo -e "\033[33mSetting permissions on the ADS-B Exchange maintainance script..."
echo -e "\033[37m"
sudo chmod 755 $BUILDDIR/adsbexchange-maint.sh

## ADD ADS-B EXCHANGE MAINTAINANCE SCRIPT TO RC.LOCAL

if ! grep -Fxq "${BUILDDIR}/adsbexchange-maint.sh &" /etc/rc.local; then
    echo -e "\033[33mAdding ADS-B Exchange maintainance script startup command to rc.local..."
    echo -e "\033[37m"
    lnum=($(sed -n '/exit 0/=' /etc/rc.local))
    ((lnum>0)) && sudo sed -i "${lnum[$((${#lnum[@]}-1))]}i ${BUILDDIR}/adsbexchange-maint.sh &\n" /etc/rc.local
fi

## RUN THE ADS-B EXCHANGE MAINTAINANCE SCRIPT

echo -e "\033[33mRunning ADS-B Exchange maintainance script..."
echo -e "\033[37m"
sudo $BUILDDIR/adsbexchange-maint.sh start &

## DISPLAY SETUP COMPLETE MESSAGE

echo -e "\033[33m"
echo "Configuration of the ADS-B Exchange feed is now complete."
echo "Please look over the output generated to be sure no errors were encountered."
echo -e "\033[37m"
read -p "Press enter to exit this script..." CONTINUE
echo ""

exit 0
