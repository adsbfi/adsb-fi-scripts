#!/bin/bash

#####################################################################################
#                        ADSB.fi SETUP SCRIPT                                       #
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
trap 'echo "------------"; echo "[ERROR] Error in line $LINENO when executing: $BASH_COMMAND"' ERR
renice 10 $$ &>/dev/null

if [[ $1 == reinstall ]]; then
    REINSTALL=yes
fi

if [ "$(id -u)" != "0" ]; then
    echo -e "\033[33m"
    echo "This script must be ran using sudo or as root."
    echo -e "\033[37m"
    exit 1
fi

if [ -f /boot/adsbfi-config.txt ]; then
    echo --------
    echo "You are using the adsb.fi image, the feed setup script does not need to be installed."
    echo --------
    exit 1
fi

function aptInstall() {
    if ! apt install -y --no-install-recommends --no-install-suggests "$@"; then
        apt update
        if ! apt install -y --no-install-recommends --no-install-suggests "$@"; then
            apt clean -y || true
            apt --fix-broken install -y || true
            apt install --no-install-recommends --no-install-suggests -y $packages
        fi
    fi
}


packages="git wget unzip curl build-essential python3-dev socat python3-venv ncurses-dev ncurses-bin uuid-runtime zlib1g-dev zlib1g"
if ! grep -E 'wheezy|jessie' /etc/os-release -qs; then
    packages+=" libzstd-dev libzstd1"
fi

if command -v apt &>/dev/null; then
    aptInstall $packages
    if ! command -v nc &>/dev/null; then
        aptInstall netcat-openbsd || true
    fi
elif command -v yum &>/dev/null; then
    yum install -y git curl socat python3-virtualenv python3-devel gcc make ncurses-devel nc uuid zlib-devel zlib libzstd-devel libzstd
elif command -v dnf &>/dev/null; then
    dnf install -y git curl socat python3-virtualenv python3-devel gcc make ncurses-devel nc uuid zlib-devel zlib libzstd-devel libzstd
fi

hash -r

function revision() {
    git rev-parse HEAD 2>/dev/null || echo "$RANDOM-$RANDOM"
}
function getGIT() {
    # getGIT $REPO $BRANCH $TARGET (directory)
    if [[ -z "$1" ]] || [[ -z "$2" ]] || [[ -z "$3" ]]; then echo "getGIT wrong usage, check your script or tell the author!" 1>&2; return 1; fi
    REPO="$1"; BRANCH="$2"; TARGET="$3"; pushd .; tmp=/tmp/getGIT-tmp.$RANDOM.$RANDOM
    if cd "$TARGET" &>/dev/null && [[ $(git remote get-url origin) == "$REPO" ]] && git fetch --depth 1 origin "$BRANCH" && git reset --hard FETCH_HEAD; then popd && return 0; fi
    popd; if ! cd /tmp || ! rm -rf "$TARGET"; then return 1; fi
    if git clone --depth 1 --single-branch --branch "$2" "$1" "$3"; then return 0; fi
    if wget -O "$tmp" "${REPO%".git"}/archive/$BRANCH.zip" && unzip "$tmp" -d "$tmp.folder"; then
        if mv -fT "$tmp.folder/$(ls $tmp.folder)" "$TARGET"; then rm -rf "$tmp" "$tmp.folder"; return 0; fi
    fi
    rm -rf "$tmp" "$tmp.folder"; return 1
}

REPO="https://github.com/d4rken/adsb-fi-scripts.git"
BRANCH="master"

IPATH=/usr/local/share/adsbfi
GIT="$IPATH/git"
mkdir -p $IPATH

LOGFILE="$IPATH/lastlog"
rm -f $LOGFILE
touch $LOGFILE

if [[ "$1" == "test" ]]; then
    cp -T -a ./ /tmp/ax_test
    GIT=/tmp/ax_test
else
    getGIT "$REPO" "$BRANCH" "$GIT" >> $LOGFILE
fi
cd "$GIT"

if diff "$GIT/update.sh" "$IPATH/update.sh" &>/dev/null; then
    rm -f "$IPATH/update.sh"
    cp "$GIT/update.sh" "$IPATH/update.sh"
    bash "$IPATH/update.sh"
    exit $?
fi

if [ -f /boot/adsb-config.txt ]; then
    source /boot/adsb-config.txt
    source /boot/adsbfi-env
else
    source /etc/default/adsbfi
    if ! grep -qs -e UAT_INPUT /etc/default/adsbfi; then
        cat >> /etc/default/adsbfi <<"EOF"

# this is the source for 978 data, use port 30978 from dump978 --raw-port
# if you're not receiving 978, don't worry about it, not doing any harm!
UAT_INPUT="127.0.0.1:30978"
EOF
    fi
fi
if [[ -z $INPUT ]] || [[ -z $INPUT_TYPE ]] || [[ -z $USER ]] \
    || [[ -z $LATITUDE ]] || [[ -z $LONGITUDE ]] || [[ -z $ALTITUDE ]] \
    || [[ -z $MLATSERVER ]] || [[ -z $TARGET ]] || [[ -z $NET_OPTIONS ]]; then
    bash "$GIT/setup.sh"
    exit 0
fi


if [[ "$LATITUDE" == 0 ]] || [[ "$LONGITUDE" == 0 ]] || [[ "$USER" == 0 ]]; then
    MLAT_DISABLED=1
else
    MLAT_DISABLED=0
fi

cp "$GIT/uninstall.sh" "$IPATH"
cp "$GIT"/scripts/*.sh "$IPATH"

UNAME=adsbfi
if ! id -u "${UNAME}" &>/dev/null
then
    # 2nd syntax is for fedora / centos
    adduser --system --home "$IPATH" --no-create-home --quiet "$UNAME" || adduser --system --home-dir "$IPATH" --no-create-home "$UNAME"
fi

echo 4
sleep 0.25

# BUILD AND CONFIGURE THE MLAT-CLIENT PACKAGE

progress=4
echo "Checking and installing prerequesites ..."

# Check that the prerequisite packages needed to build and install mlat-client are installed.

# only install chrony if chrony and ntp aren't running
if ! systemctl status chrony &>/dev/null && ! systemctl status ntp &>/dev/null; then
    required_packages="chrony "
fi


echo
bash "$IPATH/git/create-uuid.sh"

VENV=$IPATH/venv
if [[ -f /usr/local/share/adsbfi/venv/bin/python3.7 ]] && command -v python3.9 &>/dev/null;
then
    rm -rf "$VENV"
fi


MLAT_REPO="https://github.com/makrsmark/mlat-client.git"
MLAT_BRANCH="adsbfi"
MLAT_VERSION="$(git ls-remote $MLAT_REPO $MLAT_BRANCH | cut -f1 || echo $RANDOM-$RANDOM )"
if [[ $REINSTALL != yes ]] && grep -e "$MLAT_VERSION" -qs $IPATH/mlat_version \
    && grep -qs -e '#!' "$VENV/bin/mlat-client" && { systemctl is-active adsbfi-mlat &>/dev/null || [[ "${MLAT_DISABLED}" == "1" ]]; }
then
    echo
    echo "mlat-client already installed, git hash:"
    cat $IPATH/mlat_version
    echo
else
    echo
    echo "Installing mlat-client to virtual environment"
    echo
    # Check if the mlat-client git repository already exists.

    MLAT_GIT="$IPATH/mlat-client-git"

    # getGIT $REPO $BRANCH $TARGET-DIR
    getGIT $MLAT_REPO $MLAT_BRANCH $MLAT_GIT &> $LOGFILE

    cd $MLAT_GIT

    echo 34

    rm "$VENV-backup" -rf
    mv "$VENV" "$VENV-backup" -f &>/dev/null || true
    if /usr/bin/python3 -m venv $VENV >> $LOGFILE \
        && echo 36 \
        && source $VENV/bin/activate >> $LOGFILE \
        && echo 38 \
        && python3 setup.py build >> $LOGFILE \
        && echo 40 \
        && python3 setup.py install >> $LOGFILE \
        && echo 46 \
        && revision > $IPATH/mlat_version || rm -f $IPATH/mlat_version \
        && echo 48 \
    ; then
        rm "$VENV-backup" -rf
    else
        rm "$VENV" -rf
        mv "$VENV-backup" "$VENV" &>/dev/null || true
        echo "--------------------"
        echo "Installing mlat-client failed, if there was an old version it has been restored."
        echo "Will continue installation to try and get at least the feed client working."
        echo "Please repot this error to the adsbfi forums or discord."
        echo "--------------------"
    fi
fi

echo 50

# copy adsbfi-mlat service file
cp "$GIT"/scripts/adsbfi-mlat.service /lib/systemd/system

echo 60

if ls -l /etc/systemd/system/adsbfi-mlat.service 2>&1 | grep '/dev/null' &>/dev/null; then
    echo "--------------------"
    echo "CAUTION, adsbfi-mlat is masked and won't run!"
    echo "If this is unexpected for you, please report this issue"
    echo "--------------------"
    sleep 3
else
    if [[ "${MLAT_DISABLED}" == "1" ]]; then
        systemctl disable adsbfi-mlat || true
        systemctl stop adsbfi-mlat || true
    else
        # Enable adsbfi-mlat service
        systemctl enable adsbfi-mlat >> $LOGFILE || true
        # Start or restart adsbfi-mlat service
        systemctl restart adsbfi-mlat || true
    fi
fi

echo 70

# SETUP FEEDER TO SEND DUMP1090 DATA TO ADSB.fi

READSB_REPO="https://github.com/wiedehopf/readsb.git"
READSB_BRANCH="master"
if grep -E 'wheezy|jessie' /etc/os-release -qs; then
    READSB_BRANCH="jessie"
fi
READSB_VERSION="$(git ls-remote $READSB_REPO $READSB_BRANCH | cut -f1 || echo $RANDOM-$RANDOM )"
READSB_GIT="$IPATH/readsb-git"
READSB_BIN="$IPATH/feed-adsbfi"
if [[ $REINSTALL != yes ]] && grep -e "$READSB_VERSION" -qs $IPATH/readsb_version \
    && "$READSB_BIN" -V && systemctl is-active adsbfi-feed &>/dev/null
then
    echo
    echo "Feed client already installed, git hash:"
    cat $IPATH/readsb_version
    echo
else
    echo
    echo "Compiling / installing the readsb based feed client"
    echo

    #compile readsb
    echo 72

    # getGIT $REPO $BRANCH $TARGET-DIR
    getGIT "$READSB_REPO" "$READSB_BRANCH" "$READSB_GIT" &> $LOGFILE

    cd "$READSB_GIT"

    echo 74

    make clean
    make -j2 AIRCRAFT_HASH_BITS=12 >> $LOGFILE
    echo 80
    rm -f "$READSB_BIN"
    cp readsb "$READSB_BIN"
    revision > $IPATH/readsb_version || rm -f $IPATH/readsb_version

    echo
fi

#end compile readsb

cp "$GIT"/scripts/adsbfi-feed.service /lib/systemd/system

echo 82

if ! ls -l /etc/systemd/system/adsbfi-feed.service 2>&1 | grep '/dev/null' &>/dev/null; then
    # Enable adsbfi-feed service
    systemctl enable adsbfi-feed >> $LOGFILE || true
    echo 92
    # Start or restart adsbfi-feed service
    systemctl restart adsbfi-feed || true
else
    echo "--------------------"
    echo "CAUTION, adsbfi-feed.service is masked and won't run!"
    echo "If this is unexpected for you, please report this issue"
    echo "--------------------"
    sleep 3
fi

echo 94

systemctl is-active adsbfi-feed &>/dev/null || {
    rm -f $IPATH/readsb_version
    echo "---------------------------------"
    journalctl -u adsbfi-feed | tail -n10
    echo "---------------------------------"
    echo "adsbfi-feed service couldn't be started, please report this error to the adsbfi forum or discord."
    echo "Try an copy as much of the output above and include it in your report, thank you!"
    echo "---------------------------------"
    exit 1
}

echo 96
[[ "${MLAT_DISABLED}" == "1" ]] || systemctl is-active adsbfi-mlat &>/dev/null || {
    rm -f $IPATH/mlat_version
    echo "---------------------------------"
    journalctl -u adsbfi-mlat | tail -n10
    echo "---------------------------------"
    echo "adsbfi-mlat service couldn't be started, please report this error to the adsb.fi discord."
    echo "Try an copy as much of the output above and include it in your report, thank you!"
    echo "---------------------------------"
    exit 1
}

# Remove old method of starting the feed scripts if present from rc.local
# Kill the old adsb.fi scripts in case they are still running from a previous install including spawned programs
for name in adsbfi-netcat_maint.sh adsbfi-socat_maint.sh adsbfi-mlat_maint.sh; do
    if grep -qs -e "$name" /etc/rc.local; then
        sed -i -e "/$name/d" /etc/rc.local || true
    fi
    if PID="$(pgrep -f "$name" 2>/dev/null)" && PIDS="$PID $(pgrep -P $PID 2>/dev/null)"; then
        echo killing: $PIDS >> $LOGFILE 2>&1 || true
        kill -9 $PIDS >> $LOGFILE 2>&1 || true
    fi
done

# in case the mlat-client service using /etc/default/mlat-client as config is using adsb.fi as a host, disable the service
if grep -qs 'SERVER_HOSTPORT.*feed.adsb.fi' /etc/default/mlat-client &>/dev/null; then
    systemctl disable --now mlat-client >> $LOGFILE 2>&1 || true
fi

if [[ -f /etc/default/adsbfi ]]; then
    sed -i -e 's/feed.adsb.fi,30004,beast_reduce_out,feed.adsb.fi,64004/feed.adsb.fi,30004,beast_reduce_out,feed.adsb.fi,64004/' /etc/default/adsbfi || true
fi


echo 100
echo "---------------------"
echo "---------------------"

## SETUP COMPLETE

ENDTEXT="
Thanks for choosing to share your data with ADS-B.FI!

Your feed should be active within 5 minutes, you can confirm by running the following command and looking for the IP address 65.109.2.208
netstat -t -n | grep -E '30004|31090'

Question? Issues? Go here:
https://discord.gg/n9dGbkTtZm

Webinterface to show the data transmitted? Run this command:
sudo bash /usr/local/share/adsbfi/git/install-or-update-interface.sh
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

if ! timeout 5 nc -z "$INPUT_IP" "$INPUT_PORT" && command -v nc &>/dev/null; then
    #whiptail --title "ADSB.fi Setup Script" --msgbox "$ENDTEXT2" 24 73
    echo -e "$ENDTEXT2"
else
    # Display the thank you message box.
    #whiptail --title "ADSB.fi Setup Script" --msgbox "$ENDTEXT" 24 73
    echo -e "$ENDTEXT"
fi
