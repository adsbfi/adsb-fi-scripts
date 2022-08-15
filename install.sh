#!/bin/bash
set -e

REPO="https://github.com/adsbexchange/feedclient.git"
BRANCH="master"
IPATH=/usr/local/share/adsbexchange
mkdir -p $IPATH

if [ "$(id -u)" != "0" ]; then
    echo -e "\033[33m"
    echo "This script must be ran using sudo or as root."
    echo -e "\033[37m"
    exit 1
fi

if ! command -v git &>/dev/null || ! command -v wget &>/dev/null || ! command -v unzip &>/dev/null; then
    apt-get update || true; apt-get install -y --no-install-recommends --no-install-suggests git wget unzip || true
fi
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

getGIT "$REPO" "$BRANCH" "$IPATH/git"

cd "$IPATH/git"
bash "$IPATH/git/setup.sh"
