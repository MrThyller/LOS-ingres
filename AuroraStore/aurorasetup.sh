#!/bin/bash

set -e

echo "vendor/aurora/aurorasetup.sh called"

download_apk() {
    local source_apk=$1
    local destination_apk=$2

    if [ -f "$destination_apk" ]; then
        echo "$destination_apk exists: not downloading"
    else
        echo "downloading $source_apk to $destination_apk"
        curl -fL --output "$destination_apk" "$source_apk"
    fi
}

get-aurora-components() {
    local aurora_store_url="https://auroraoss.com/downloads/AuroraStore/Latest/latest.apk"
    local aurora_services_url="https://gitlab.com/-/project/8363046/uploads/c22e95975571e9db143567690777a56e/AuroraServices_v1.1.1.apk"

    download_apk "$aurora_store_url" "AuroraStore.apk"
    download_apk "$aurora_services_url" "AuroraServices.apk"
}

cd vendor/aurora
get-aurora-components
cd ../..

set +e
