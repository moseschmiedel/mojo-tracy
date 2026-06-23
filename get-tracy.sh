#!/usr/bin/env bash

set -euo pipefail

# Loads .env file while ignoring comments
export $(grep -v '^#' TRACY.env | xargs)

current_dir_name="${PWD##*/}"

# Downloads specific `version` of Tracy.
#
# Creates a new `tracy` clone if it does not exist yet, otherwise updates it to the specified `version`.
download_tracy() {
    version="$1"
    echo "Downloading Tracy..."

    if [ ! -d tracy ]; then
        git clone --depth 1 --branch "$version" "https://github.com/wolfpld/tracy.git" "tracy"
    else
        git -C tracy fetch --tags
        git -C tracy reset --hard "$version"
    fi
}


if [ $current_dir_name != "mojo-tracy" ]; then
    echo "Please run this script from the 'mojo-tracy' directory."
    exit 1
fi

download_tracy "$TRACY_VERSION"
