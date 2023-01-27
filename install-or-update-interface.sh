#!/bin/bash

set -e
trap 'echo "------------"; echo "[ERROR] Error in line $LINENO when executing: $BASH_COMMAND"' ERR

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

REPO="https://github.com/wiedehopf/tar1090"
BRANCH="master"
GIT="/usr/local/share/tar1090/git"

getGIT "$REPO" "$BRANCH" "$GIT"

bash "$GIT/install.sh" "/run/adsbfi-feed" "adsbfi"
