#!/bin/bash
# Helper script to mount Raspberry Pi image partitions

set -e

IMAGE_FILE="$1"
MOUNT_POINT="$2"

if [ -z "$IMAGE_FILE" ] || [ -z "$MOUNT_POINT" ]; then
    echo "Usage: $0 <image-file> <mount-point>"
    exit 1
fi

if [ ! -f "$IMAGE_FILE" ]; then
    echo "Error: Image file not found: $IMAGE_FILE"
    exit 1
fi

if [ $EUID -ne 0 ]; then
    echo "Error: This script must be run as root"
    exit 1
fi

# Create mount point
mkdir -p "$MOUNT_POINT"

# Setup loop device
echo "Setting up loop device..."
LOOP_DEV=$(losetup -f --show "$IMAGE_FILE")
echo "Loop device: $LOOP_DEV"

# Map partitions
echo "Mapping partitions..."
kpartx -a "$LOOP_DEV"
sleep 2

# Find partition devices
BOOT_PART="/dev/mapper/$(basename $LOOP_DEV)p1"
ROOT_PART="/dev/mapper/$(basename $LOOP_DEV)p2"

echo "Boot partition: $BOOT_PART"
echo "Root partition: $ROOT_PART"

# Mount partitions
echo "Mounting root partition..."
mount "$ROOT_PART" "$MOUNT_POINT"

echo "Mounting boot partition..."
mkdir -p "$MOUNT_POINT/boot/firmware"
mount "$BOOT_PART" "$MOUNT_POINT/boot/firmware"

echo "Image mounted successfully at $MOUNT_POINT"
echo "Loop device: $LOOP_DEV" > "${MOUNT_POINT}/../loop_device"

# Copy qemu static for ARM emulation if available
if [ -f /usr/bin/qemu-aarch64-static ]; then
    echo "Copying qemu-aarch64-static for ARM emulation..."
    cp /usr/bin/qemu-aarch64-static "$MOUNT_POINT/usr/bin/"
fi

echo "Done! Image is mounted and ready for customization."