#!/bin/bash
set -e

REPO="https://github.com/adsbxchange/adsb-exchange.git"
BRANCH="master"
IPATH=/usr/local/share/adsbexchange
mkdir -p $IPATH

if [ "$(id -u)" != "0" ]; then
    echo -e "\033[33m"
    echo "This script must be ran using sudo or as root."
    echo -e "\033[37m"
    exit 1
fi

if ! command -v git &>/dev/null; then
    apt-get update || true
    apt-get install -y --no-install-recommends --no-install-suggests git || true
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

getGIT "$REPO" "$BRANCH" "$IPATH/git"

cd "$IPATH/git"
bash "$IPATH/git/setup.sh"
