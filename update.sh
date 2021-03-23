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

if [ "$(id -u)" != "0" ]; then
    echo -e "\033[33m"
    echo "This script must be ran using sudo or as root."
    echo -e "\033[37m"
    exit 1
fi

if [ -f /boot/adsb-config.txt ]; then
    echo --------
    echo "You are using the adsbx image, the feed setup script does not need to be installed."
    echo --------
    exit 1
fi

IPATH=/usr/local/share/adsbexchange
GIT="$IPATH/git"
mkdir -p $IPATH

source /etc/default/adsbexchange
if [[ -z "$INPUT" ]] || [[ -z "$USER" ]] || [[ -z "$LATITUDE" ]] || [[ -z "$LONGITUDE" ]] || [[ -z "$ALTITUDE" ]]; then
    echo "---------------------------------"
    echo "Please rerun the complete setup, configuration file /etc/default/adsbexchange is not complete!"
    echo "---------------------------------"
    exit 1
fi

function getGIT() {
    # getGIT $REPO $BRANCH $TARGET-DIR
    if [[ -z "$1" ]] || [[ -z "$2" ]] || [[ -z "$3" ]]; then
        echo "getGIT wrong usage, check your script or tell the author!" 1>&2
        return 1
    fi
    if ! cd "$3" &>/dev/null || ! git fetch origin "$2" || ! git reset --hard FETCH_HEAD; then
        if ! rm -rf "$3" || ! git clone --depth 2 --single-branch --branch "$2" "$1" "$3"; then
            return 1
        fi
    fi
    return 0
}

REPO="https://github.com/adsbxchange/adsb-exchange.git"
BRANCH="master"

getGIT "$REPO" "$BRANCH" "$IPATH/git"
cd "$IPATH/git"

# remove previously used folder to avoid confusion
rm -rf /usr/local/share/adsb-exchange &>/dev/null

LOGFILE="$IPATH/lastlog"
rm -f $LOGFILE
touch $LOGFILE

cp uninstall.sh $IPATH

if ! id -u adsbexchange &>/dev/null
then
    adduser --system --home $IPATH --no-create-home --quiet adsbexchange
fi

echo 4
sleep 0.25

# BUILD AND CONFIGURE THE MLAT-CLIENT PACKAGE

echo "Checking and installing prerequesites ..."

# Check that the prerequisite packages needed to build and install mlat-client are installed.

# only install ntp if chrony and ntpsec aren't running
if ! systemctl status chrony &>/dev/null && ! systemctl status ntpsec &>/dev/null; then
    required_packages="ntp "
fi

progress=4

APT_UPDATED="false"

if command -v apt &>/dev/null; then
    required_packages+="git curl build-essential python3-dev socat python3-venv libncurses5-dev netcat uuid-runtime zlib1g-dev zlib1g"
    APT_INSTALL="false"
    INSTALLED="$(dpkg-query -W -f='${PACKAGE} ${STATUS}\n')"
    packages=""
    for package in $required_packages; do
        #if [ $(dpkg-query -W -f='${STATUS}' $package 2>/dev/null | grep -c "ok installed") -eq 0 ]; then
        if ! echo "$INSTALLED" | grep -qs -E -e "^$package install ok installed"; then
            APT_INSTALL="true"
            packages+=" $package"
        fi
        progress=$((progress+1))
        echo $progress
    done

    if [[ "$APT_INSTALL" == "true" ]]; then
        [[ "$APT_UPDATED" == "false" ]] && apt update && APT_UPDATED="true"
        [[ "$APT_UPDATED" == "false" ]] && apt update  && APT_UPDATED="true"
        [[ "$APT_UPDATED" == "false" ]] && apt update  && APT_UPDATED="true"
        echo Installing $packages
        if ! apt install --no-install-recommends --no-install-suggests -y $packages; then
            # retry
            apt clean
            apt --fix-broken install -y
            apt install --no-install-recommends --no-install-suggests -y $packages
        fi
    fi
elif command -v yum &>/dev/null; then
    required_packages+="git curl socat python3-virtualenv python3-devel gcc make ncurses-devel nc uuid zlib-devel zlib"
    yum install -y $required_packages
fi

hash -r

echo
bash "$IPATH/git/create-uuid.sh"

MLAT_REPO="https://github.com/adsbxchange/mlat-client.git"
MLAT_BRANCH="master"
MLAT_VERSION="$(git ls-remote $MLAT_REPO $MLAT_BRANCH | cut -f1)"
VENV=$IPATH/venv
if ! grep -e "$MLAT_VERSION" -qs $IPATH/mlat_version || ! [[ -f "$VENV/bin/mlat-client" ]]; then
    echo
    echo "Installing mlat-client to virtual environment"
    echo
    # Check if the mlat-client git repository already exists.

    MLAT_GIT="$IPATH/mlat-client-git"

    # getGIT $REPO $BRANCH $TARGET-DIR
    getGIT $MLAT_REPO $MLAT_BRANCH $MLAT_GIT

    cd $MLAT_GIT

    echo 34
    sleep 0.25


    rm "$VENV" -rf
    /usr/bin/python3 -m venv $VENV >> $LOGFILE && echo 36 \
        && source $VENV/bin/activate >> $LOGFILE && echo 38 \
        && python3 setup.py build >> $LOGFILE && echo 40 \
        && python3 setup.py install >> $LOGFILE && echo 46 \
        && git rev-parse HEAD > $IPATH/mlat_version

    echo ""
else
    echo
    echo "mlat-client already installed, git hash:"
    cat $IPATH/mlat_version
    echo
fi

echo 50
cd $CURRENT_DIR

# copy adsbexchange-mlat service file
cp "$GIT"/scripts/adsbexchange-mlat.sh $IPATH
cp "$GIT"/scripts/adsbexchange-mlat.service /lib/systemd/system

# Enable adsbexchange-mlat service
systemctl enable adsbexchange-mlat

echo 70
sleep 0.25

# SETUP FEEDER TO SEND DUMP1090 DATA TO ADS-B EXCHANGE

READSB_REPO="https://github.com/adsbxchange/readsb.git"
READSB_BRANCH="master"
READSB_VERSION="$(git ls-remote $READSB_REPO $READSB_BRANCH | cut -f1)"
READSB_GIT="$IPATH/readsb-git"
READSB_BIN="$IPATH/feed-adsbx"
if ! grep -e "$READSB_VERSION" -qs $IPATH/readsb_version || ! [[ -f "$READSB_BIN" ]]; then
    echo
    echo "Compiling / installing the readsb based feed client"
    echo

    #compile readsb
    echo 72

    # getGIT $REPO $BRANCH $TARGET-DIR
    getGIT "$READSB_REPO" "$READSB_BRANCH" "$READSB_GIT"

    cd "$READSB_GIT"

    echo 74

    if make -j3 AIRCRAFT_HASH_BITS=12 >> $LOGFILE && rm -f "$READSB_BIN" && cp readsb "$READSB_BIN"; then
        git rev-parse HEAD > $IPATH/readsb_version 2>> $LOGFILE
    fi

    echo
else
    echo
    echo "Feed client already installed, git hash:"
    cat $IPATH/readsb_version
    echo
fi

# back to the working dir for install script
cd $SCRIPT_DIR
#end compile readsb

cp "$GIT"/scripts/adsbexchange-feed.sh $IPATH
cp "$GIT"/scripts/adsbexchange-feed.service /lib/systemd/system

echo 82
sleep 0.25

# Enable adsbexchange-feed service
systemctl enable adsbexchange-feed

echo 88
sleep 0.25

# Remove old method of starting the feed scripts if present from rc.local
# Kill the old adsbexchange scripts in case they are still running from a previous install including spawned programs
for name in adsbexchange-netcat_maint.sh adsbexchange-socat_maint.sh adsbexchange-mlat_maint.sh; do
    if grep -qs -e "$name" /etc/rc.local; then
        sed -i -e "/$name/d" /etc/rc.local || true
    fi
    if PID="$(pgrep -f "$name" 2>/dev/null)" && PIDS="$PID $(pgrep -P $PID 2>/dev/null)"; then
        echo killing: $PIDS >> $LOGFILE 2>&1 || true
        kill -9 $PIDS >> $LOGFILE 2>&1 || true
    fi
done

# in case the mlat-client service using /etc/default/mlat-client as config is using adsbexchange as a host, disable the service
if grep -qs 'SERVER_HOSTPORT.*feed.adsbexchange.com' /etc/default/mlat-client &>/dev/null; then
    systemctl disable --now mlat-client >> $LOGFILE 2>&1 || true
fi

echo 94

# Start or restart adsbexchange-feed service
systemctl restart adsbexchange-feed

echo 96

# Start or restart adsbexchange-mlat service
systemctl restart adsbexchange-mlat

echo 100

## SETUP COMPLETE

ENDTEXT="
Setup is now complete.

You should now be feeding data to ADS-B Exchange.

Thanks again for choosing to share your data with ADS-B Exchange!

If you're curious, check your feed status after 5 min:

https://adsbexchange.com/myip/
http://adsbx.org/sync

If you have questions or encountered any issues while using this script feel free to post them to one of the following places:

https://www.adsbexchange.com/forum/threads/adsbexchange-setup-scripts.631609/
https://discord.gg/n9dGbkTtZm
"

INPUT_IP=$(echo $INPUT | cut -d: -f1)
INPUT_PORT=$(echo $INPUT | cut -d: -f2)

ENDTEXT2="
---------------------
No data available from IP $INPUT_IP on port $INPUT_PORT!
---------------------
If your data source is another device / receiver, see the advice here:
https://github.com/adsbxchange/wiki/wiki/Datasource-other-device
"
if [ -f /etc/fr24feed.ini ] || [ -f /etc/rb24.ini ]; then
    ENDTEXT2+="
It looks like you are running FR24 or RB24
This means you will need to install a stand-alone decoder so data are avaible on port 30005!

If you have the SDR connected to this device, we recommend using this script to install and configure a stand-alone decoder:

https://github.com/wiedehopf/adsb-scripts/wiki/Automatic-installation-for-readsb
---------------------
"
else
    ENDTEXT2+="
If you have connected an SDR but not yet installed an ADS-B decoder for it,
we recommend this script:

https://github.com/wiedehopf/adsb-scripts/wiki/Automatic-installation-for-readsb
---------------------
"
fi

if ! nc -z "$INPUT_IP" "$INPUT_PORT" && command -v nc &>/dev/null; then
    whiptail --title "ADS-B Exchange Setup Script" --msgbox "$ENDTEXT2" 24 73
    echo -e "$ENDTEXT2"
else
    # Display the thank you message box.
    whiptail --title "ADS-B Exchange Setup Script" --msgbox "$ENDTEXT" 24 73
    echo -e "$ENDTEXT"
fi
