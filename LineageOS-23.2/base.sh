#!/usr/bin/env bash
#-------------------------------------------------------------------#
# Autor       : WhoFoss <https://github.com/WhoFoss> & Tenório <https://github.com/tenorio-md> 
# Programa    : los23.2.sh
# DESCRIÇÃO   :
# lineageOS-MicroG for ingres, forked by sapphire(Redmi note 13 4g)

# Deps:
#   - git
#   - repo (Android repo tool)
#   - wget / curl
#   - bash >= 4
#!/usr/bin/env bash
#-------------------------------------------------------------------#
# LineageOS 23.2 MicroG - ingres
#-------------------------------------------------------------------#

set -Eeuo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RESET='\033[0m'

echo -en "\033[?25l"
trap 'echo -en "\033[?12l\033[?25h"' EXIT

# ============================================================
# FUNÇÕES BÁSICAS
# ============================================================

error_exit() {
    echo -e "${RED}[ERROR] $1${RESET}"
    exit 1
}

print_header() {
    local message="$1"
    local border_char="${2:-=}"
    local color="${3:-$GREEN}"
    local length=${#message}
    local border

    border=$(printf "%${length}s" | tr " " "$border_char")

    echo -e "${color}${border}${RESET}"
    echo -e "${color}${message}${RESET}"
    echo -e "${color}${border}${RESET}"
}

check_repo_valid() {
    command -v repo >/dev/null 2>&1 \
        || error_exit "repo command not found"

    command -v git >/dev/null 2>&1 \
        || error_exit "git command not found"

    command -v wget >/dev/null 2>&1 \
        || error_exit "wget command not found"

    echo -e "${GREEN}Required commands found.${RESET}"
}

# ============================================================
# DIRETÓRIO
# ============================================================

setup_lineage_dir() {
    LINEAGE_DIR="Los"
    TARGET_DIR="$HOME/$LINEAGE_DIR"

    echo -e "${CYAN}Creating LineageOS directory...${RESET}"

    if [ ! -d "$TARGET_DIR" ]; then
        mkdir -p "$TARGET_DIR" \
            || error_exit "Failed to create $TARGET_DIR"

        echo -e "${GREEN}Created $TARGET_DIR${RESET}"
    else
        echo -e "${YELLOW}$TARGET_DIR already exists${RESET}"
    fi

    cd "$TARGET_DIR" \
        || error_exit "Failed to enter $TARGET_DIR"

    echo -e "${GREEN}Working directory: $PWD${RESET}"
}

# ============================================================
# REPO INIT
# ============================================================

init_lineage() {
    echo -e "${CYAN}Initializing LineageOS 23.2...${RESET}"

    if [ ! -d ".repo" ]; then
        repo init \
            -u https://github.com/LineageOS/android.git \
            -b lineage-23.2 \
            --git-lfs \
            || error_exit "repo init failed"

        print_header "LineageOS 23.2 repo initialized"
    else
        echo -e "${YELLOW}.repo already exists. Skipping repo init.${RESET}"
    fi
}

# ============================================================
# PRIMEIRO SYNC
# ============================================================

first_sync() {
    echo -e "${RED}Starting initial LineageOS sync...${RESET}"

    repo sync \
        || error_exit "Initial repo sync failed"

    print_header "Initial LineageOS sync complete"
}

# ============================================================
# ROOM SERVICE
# ============================================================

create_roomservice_manifest() {
    echo -e "${CYAN}Creating roomservice.xml...${RESET}"

    mkdir -p .repo/local_manifests

    cat > .repo/local_manifests/roomservice.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<manifest>

    <!-- REMOTE -->
    <remote
        name="local-github"
        fetch="https://github.com/"
        sync-c="true"
        sync-j="4" />

    <!-- ================================================== -->
    <!-- INGRES -->
    <!-- ================================================== -->

    <project
        name="Ingres-Centre/android_device_xiaomi_ingres"
        path="device/xiaomi/ingres"
        remote="local-github"
        revision="lineage-23.2" />

    <project
        name="Ingres-Centre/proprietary_vendor_xiaomi_ingres"
        path="vendor/xiaomi/ingres"
        remote="local-github"
        revision="lineage-23.1" />

    <!-- ================================================== -->
    <!-- SM8450 COMMON -->
    <!-- ================================================== -->

    <project
        name="LineageOS/android_device_xiaomi_sm8450-common"
        path="device/xiaomi/sm8450-common"
        remote="local-github"
        revision="lineage-23.2" />

    <project
        name="TheMuppets/proprietary_vendor_xiaomi_sm8450-common"
        path="vendor/xiaomi/sm8450-common"
        remote="local-github"
        revision="lineage-23.2" />

    <!-- ================================================== -->
    <!-- KERNEL -->
    <!-- ================================================== -->

    <project
        name="Ingres-Centre/android_kernel_xiaomi_sm8450"
        path="kernel/xiaomi/sm8450"
        remote="local-github"
        revision="lineage-23.2" />

    <project
        name="LineageOS/android_kernel_xiaomi_sm8450-modules"
        path="kernel/xiaomi/sm8450-modules"
        remote="local-github"
        revision="lineage-23.2" />

    <project
        name="Ingres-Centre/android_kernel_xiaomi_sm8450-devicetrees"
        path="kernel/xiaomi/sm8450-devicetrees"
        remote="local-github"
        revision="lineage-23.2" />

    <!-- ================================================== -->
    <!-- LINEAGE INTERFACES -->
    <!-- ================================================== -->

    <remove-project
        name="LineageOS/android_hardware_lineage_interfaces" />

    <project
        name="Ingres-Centre/android_hardware_lineage_interfaces"
        path="hardware/lineage/interfaces"
        remote="local-github"
        revision="lineage-23.2" />

    <!-- ================================================== -->
    <!-- SEPOLICY -->
    <!-- ================================================== -->

    <remove-project
        name="LineageOS/android_device_lineage_sepolicy" />

    <project
        name="Ingres-Centre/android_device_lineage_sepolicy"
        path="device/lineage/sepolicy"
        remote="local-github"
        revision="lineage-23.2" />

    <!-- ================================================== -->
    <!-- HARDWARE -->
    <!-- ================================================== -->

    <project
        name="LineageOS/android_hardware_xiaomi"
        path="hardware/xiaomi"
        remote="local-github"
        revision="lineage-23.2" />

</manifest>
EOF

    print_header "roomservice.xml created"
}

# ============================================================
# MICROG MANIFEST
# ============================================================

create_microg_manifest() {
    echo -e "${CYAN}Creating MicroG manifest...${RESET}"

    mkdir -p .repo/local_manifests

    cat > .repo/local_manifests/microg.xml << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<manifest>

    <remote
        name="lineageos4microg"
        fetch="https://github.com/lineageos4microg/" />

    <project
        path="vendor/partner_gms"
        name="android_vendor_partner_gms"
        remote="lineageos4microg"
        revision="master" />

</manifest>
EOF

    print_header "microg.xml created"
}

# ============================================================
# SEGUNDO SYNC
# ============================================================

second_sync() {
    echo -e "${RED}Syncing device trees and MicroG...${RESET}"

    repo sync \
        || error_exit "Device tree / MicroG repo sync failed"

    print_header "Device trees and MicroG sync complete"
}

# ============================================================
# PRODUCT PACKAGES
# ============================================================

add_to_device_mk() {
    local package="$1"
    local device_mk="device/xiaomi/ingres/device.mk"

    if [ ! -f "$device_mk" ]; then
        echo -e "${YELLOW}device.mk not found. Skipping $package.${RESET}"
        return 0
    fi

    if ! grep -q "^PRODUCT_PACKAGES += $package$" "$device_mk"; then
        echo "PRODUCT_PACKAGES += $package" >> "$device_mk"
        print_header "$package added to device.mk"
    else
        echo -e "${YELLOW}$package already exists.${RESET}"
    fi
}

# ============================================================
# DUCKDUCKGO
# ============================================================

install_duckduckgo() {
    echo -e "${CYAN}Installing DuckDuckGo prebuilt...${RESET}"

    local DIR="device/xiaomi/ingres/prebuilt/duckduckgo"

    mkdir -p "$DIR"

    wget -q --show-progress \
        -O "$DIR/DuckDuckGo.apk" \
        "https://f-droid.org/repo/com.duckduckgo.mobile.android_50010000.apk" \
        || {
            echo -e "${YELLOW}DuckDuckGo download failed. Skipping.${RESET}"
            return 0
        }

    cat > "$DIR/Android.bp" << 'EOF'
android_app_import {
    name: "DuckDuckGo",
    apk: "DuckDuckGo.apk",
    presigned: true,
    dex_preopt: {
        enabled: false,
    },
}
EOF

    add_to_device_mk "DuckDuckGo"

    print_header "DuckDuckGo installed"
}

# ============================================================
# THUNDERBIRD
# ============================================================

install_thunderbird() {
    echo -e "${CYAN}Installing Thunderbird prebuilt...${RESET}"

    local DIR="device/xiaomi/ingres/prebuilt/thunderbird"

    mkdir -p "$DIR"

    wget -q --show-progress \
        -O "$DIR/Thunderbird.apk" \
        "https://f-droid.org/repo/net.thunderbird.android_23.apk" \
        || error_exit "Failed to download Thunderbird.apk"

    cat > "$DIR/Android.bp" << 'EOF'
android_app_import {
    name: "Thunderbird",
    apk: "Thunderbird.apk",
    presigned: true,
    preprocessed: true,
    dex_preopt: {
        enabled: false,
    },
}
EOF

    add_to_device_mk "Thunderbird"

    print_header "Thunderbird installed"
}

# ============================================================
# AURORA STORE
# ============================================================

install_aurorastore() {
    echo -e "${CYAN}Installing AuroraStore...${RESET}"

    rm -rf vendor/aurora

    git clone \
        --depth 1 \
        -b 12L \
        https://github.com/MSe1969/AuroraStore-prebuilt.git \
        vendor/aurora \
        || error_exit "Failed to clone AuroraStore"

    rm -rf vendor/aurora/.git

    add_to_device_mk "AuroraStore"
    add_to_device_mk "AuroraServices"

    print_header "AuroraStore installed"
}

# ============================================================
# PRIVACY APPS
# ============================================================

add_privacy_apps() {
    echo -e "${CYAN}Installing privacy applications...${RESET}"

    install_duckduckgo
    install_thunderbird
    install_aurorastore

    print_header "Privacy applications complete"
}

# ============================================================
# DESATIVAR GAPPS
# ============================================================

rgapps() {
    local MK_FILE="device/xiaomi/ingres/lineage_ingres.mk"

    if [ ! -f "$MK_FILE" ]; then
        echo -e "${YELLOW}$MK_FILE not found. Skipping GApps changes.${RESET}"
        return 0
    fi

    echo -e "${CYAN}Disabling stock GApps...${RESET}"

    if grep -q '^-include vendor/gms/products/gms.mk$' "$MK_FILE"; then
        sed -i \
            's/^-include vendor\/gms\/products\/gms.mk$/#-include vendor\/gms\/products\/gms.mk/' \
            "$MK_FILE"
    fi

    local flags=(
        "TARGET_SUPPORTS_GOOGLE_RECORDER"
        "TARGET_INCLUDE_STOCK_ARCORE"
        "TARGET_INCLUDE_GOOGLE_COMMS"
        "TARGET_INCLUDE_PIXEL_LAUNCHER"
        "TARGET_INCLUDE_LIVE_WALLPAPERS"
    )

    local flag

    for flag in "${flags[@]}"; do
        if grep -q "^${flag} := true$" "$MK_FILE"; then
            sed -i "s/^${flag} := true$/${flag} := false/" "$MK_FILE"
        fi
    done

    print_header "Stock GApps disabled"
}

# ============================================================
# SIGNATURE SPOOFING
# ============================================================

patch_signature_spoofing() {
    local COMPUTER_ENGINE="frameworks/base/services/core/java/com/android/server/pm/ComputerEngine.java"

    if [ ! -f "$COMPUTER_ENGINE" ]; then
        echo -e "${YELLOW}ComputerEngine.java not found. Skipping Signature Spoofing.${RESET}"
        return 0
    fi

    cp "$COMPUTER_ENGINE" "${COMPUTER_ENGINE}.backup"

    if grep -q 'if (!isDebuggable())' "$COMPUTER_ENGINE"; then
        sed -i '/if (!isDebuggable()) {/{N;N;d}' "$COMPUTER_ENGINE"
        print_header "Signature Spoofing patch applied"
    else
        echo -e "${YELLOW}Signature Spoofing block not found or already patched.${RESET}"
    fi
}

# ============================================================
# VERSION / NOME DA ROM
# ============================================================

patch_version_mk() {
    local version_mk="vendor/lineage/config/version.mk"

    if [ ! -f "$version_mk" ]; then
        echo -e "${YELLOW}version.mk not found. Skipping version patch.${RESET}"
        return 0
    fi

    cp "$version_mk" "${version_mk}.backup"

    # Remove versões anteriores do patch
    sed -i '/# Add MicroG suffix/d' "$version_mk"
    sed -i '/# Add custom build tag/d' "$version_mk"

    # Remove linhas antigas contendo MG adicionadas pelo script
    sed -i '/LINEAGE_VERSION_SUFFIX := $(LINEAGE_VERSION_SUFFIX)-MG/d' "$version_mk"

    if ! grep -q 'LINEAGE_VERSION_SUFFIX := .*MicroG' "$version_mk"; then
        cat >> "$version_mk" << 'EOF'

# LineageOS MicroG custom suffix
LINEAGE_VERSION_SUFFIX := $(LINEAGE_VERSION_SUFFIX)-MicroG-ingres

ifneq ($(BUILD_TAG),)
    LINEAGE_VERSION_SUFFIX := $(LINEAGE_VERSION_SUFFIX)-$(BUILD_TAG)
endif
EOF
    fi

    print_header "ROM version set to LineageOS-MicroG-ingres"
}

# ============================================================
# BUILD CONFIG
# ============================================================

setup_build_environment() {
    echo -e "${CYAN}Setting up build environment...${RESET}"

    source build/envsetup.sh

    export BUILD_USERNAME=Torquatox7
    export BUILD_HOSTNAME=LineageOS-MicroG
    export SKIP_ABI_CHECKS=true
    export WITH_GMS=true

    print_header "Build environment ready"
}

# ============================================================
# MAIN
# ============================================================

clear

check_repo_valid

# 1. ~/Los
setup_lineage_dir

# 2. repo init
init_lineage

# 3. PRIMEIRO SYNC
first_sync

# 4. roomservice.xml
create_roomservice_manifest

# 5. microg.xml
create_microg_manifest

# 6. SEGUNDO SYNC
second_sync

# 7. Desativar GApps
rgapps

# 8. Signature Spoofing
patch_signature_spoofing

# 9. Nome/versionamento
patch_version_mk

# 10. Apps
add_privacy_apps

# 11. Ambiente de build
setup_build_environment

# 12. Build
echo -e "${RED}Starting LineageOS-MicroG build...${RESET}"

brunch ingres user \
    || error_exit "Brunch failed"

print_header "LineageOS-MicroG build finished"
