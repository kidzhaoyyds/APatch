#!/system/bin/sh
#######################################################################################
# APatch Boot Image Patcher
#######################################################################################
#
# Usage: boot_patch.sh <superkey> <bootimage> [ARGS_PASS_TO_KPTOOLS]
#
# This script should be placed in a directory with the following files:
#
# File name          Type          Description
#
# boot_patch.sh      script        A script to patch boot image for APatch.
#                  (this file)      The script will use files in its same
#                                  directory to complete the patching process.
# bootimg            binary        The target boot image
# kpimg              binary        KernelPatch core Image
# kptools            executable    The KernelPatch tools binary to inject kpimg to kernel Image
# magiskboot         executable    Magisk tool to unpack boot.img.
#
#######################################################################################

ARCH=$(getprop ro.product.cpu.abi)

# Load utility functions
. ./util_functions.sh

echo "****************************"
echo " APatch Boot Image Patcher"
echo "****************************"

SUPERKEY=$1
BOOTIMAGE=$2
shift 2

[ -z "$SUPERKEY" ] && { echo "- SuperKey empty!"; exit 1; }
[ -e "$BOOTIMAGE" ] || { echo "- $BOOTIMAGE does not exist!"; exit 1; }

# Check for dependencies
command -v ./magiskboot >/dev/null 2>&1 || { echo "- Command magiskboot not found!"; exit 1; }
command -v ./kptools >/dev/null 2>&1 || { echo "- Command kptools not found!"; exit 1; }

if [ ! -f kernel ]; then
echo "- Unpacking boot image"
./magiskboot unpack "$BOOTIMAGE" >/dev/null 2>&1
  if [ $? -ne 0 ]; then
    echo "- Unpack error: $?"
    exit $?
  fi
fi

mv kernel kernel.ori

echo "- Patching kernel"

set -x
./kptools -p -i kernel.ori -s "$SUPERKEY" -k kpimg -o kernel "$@"
set +x

if [ $? -ne 0 ]; then
  echo "- Patch kernel error: $?"
  exit $?
fi

echo "- Repacking boot image"
./magiskboot repack "$BOOTIMAGE" >/dev/null 2>&1

if [ $? -ne 0 ]; then
  echo "- Repack error: $?"
  exit $?
fi

# flash
if [ -b "$BOOTIMAGE" ] || [ -c "$BOOTIMAGE" ] && [ -f "new-boot.img" ]; then
  echo "- Flashing new boot image"
  flash_image new-boot.img "$BOOTIMAGE"
  if [ $? -ne 0 ]; then
    echo "- Flash error: $?"
    exit $?
  fi
fi

echo "- Flash successful"
