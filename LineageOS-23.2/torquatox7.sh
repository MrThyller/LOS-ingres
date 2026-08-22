#!/usr/bin/env bash
#-------------------------------------------------------------------#
# Autor       : WhoFoss <https://github.com/WhoFoss> & Tenório <https://github.com/tenorio-md> 
# Programa    : los23.2.sh
# DESCRIÇÃO   :
# lineageOS-MicroG for ingres, forked by sapphire(Redmi note 13 4g)
#-------------------------------------------------------------------#
# LineageOS 23.2 MicroG - ingres
#-------------------------------------------------------------------#

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
        sync-j="48" />

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
# SYNC
# ============================================================

sync_lineage() {
    echo -e "${RED}Starting LineageOS sync...${RESET}"

    repo sync -j"$(nproc --all)" --force-sync \
        || error_exit "Repo sync failed"

    print_header "Repo sync complete"
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
    rm -rf vendor/aurora/Android.mk

    cat > vendor/aurora/Android.mk << 'EOF'
    # AuroraStore as a regular system app
#
# Prebuilt content taken from:
# https://gitlab.com/AuroraOSS/AuroraStore/tags
#
LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)

LOCAL_MODULE := AuroraStore
LOCAL_SRC_FILES := AuroraStore_4.6.4.apk
LOCAL_MODULE_CLASS := APPS
LOCAL_MODULE_SUFFIX := $(COMMON_ANDROID_PACKAGE_SUFFIX)
LOCAL_CERTIFICATE := PRESIGNED
LOCAL_OPTIONAL_USES_LIBRARIES := \
    androidx.window.extensions \
    androidx.window.sidecar
LOCAL_PRODUCT_MODULE := true
LOCAL_REPLACE_PREBUILT_APK_INSTALLED := $(LOCAL_PATH)/$(LOCAL_SRC_FILES)

include $(BUILD_PREBUILT)
EOF
    
add_to_device_mk "AuroraStore"
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
# BUILD CONFIG
# ============================================================

setup_build_environment() {
    echo -e "${CYAN}Setting up build environment...${RESET}"

    source build/envsetup.sh

    export BUILD_USERNAME=Torquatox7
    export BUILD_HOSTNAME=LineageMG
    export SKIP_ABI_CHECKS=true
    export WITH_GMS=true

    print_header "Build environment ready"
}

# ============================================================
# MAIN
# ============================================================

clear && check_repo_valid

# ~/Los
setup_lineage_dir

# repo init
init_lineage

# Manifests locais (device, kernel, MicroG)
create_roomservice_manifest
create_microg_manifest

sync_lineage
patch_signature_spoofing

# Ambiente de build
setup_build_environment

# Build
echo -e "${RED}Starting LineageMG build...${RESET}"

brunch ingres user || error_exit "Brunch failed"

