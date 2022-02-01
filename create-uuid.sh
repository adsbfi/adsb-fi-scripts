#!/bin/bash

if [ -f /boot/adsb-config.txt ]; then
    UUID_FILE="/boot/adsbx-uuid"
else
    mkdir -p /usr/local/share/adsbexchange
    UUID_FILE="/usr/local/share/adsbexchange/adsbx-uuid"
    # move old file position
    if [ -f /boot/adsbx-uuid ]; then
        mv -f /boot/adsbx-uuid $UUID_FILE
    fi
fi

function aptInstall() {
    if ! apt install -y --no-install-recommends --no-install-suggests "$@"; then
        apt update
        apt install -y --no-install-recommends --no-install-suggests "$@"
    fi
}
function generateUUID() {
    # Let's make sure the UUID tools are installed...
    if ! command -v uuidgen &>/dev/null; then
        echo "Can't find uuidgen in path, trying to install uuidgen..."
        aptInstall uuid-runtime
        if ! command -v uuidgen &>/dev/null; then
            echo "Failed to install uuid-runtime package - need manual intervention!"
            sleep 60
            exit 10
        fi
    fi

    rm -f $UUID_FILE
    sleep 0.$RANDOM; sleep 0.$RANDOM
    UUID=$(uuidgen)
    echo New UUID: $UUID
    echo $UUID > $UUID_FILE
}

# Check for a (valid) UUID...
if [ -f $UUID_FILE ]; then
    UUID=$(cat $UUID_FILE)
    if ! [[ $UUID =~ ^\{?[A-F0-9a-f]{8}-[A-F0-9a-f]{4}-[A-F0-9a-f]{4}-[A-F0-9a-f]{4}-[A-F0-9a-f]{12}\}?$ ]]; then
        # Data in UUID file is invalid.  Regenerate it!
        echo "WARNING: Data in UUID file was invalid.  Regenerating UUID."
        generateUUID
    else
        echo "Using existing valid UUID ($UUID) from $UUID_FILE"
    fi
else
    # not found generate uuid and save it
    echo "WARNING: No UUID file found, generating new UUID..."
    generateUUID
fi

exit 0
