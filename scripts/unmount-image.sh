#!/bin/bash
# Helper script to unmount Raspberry Pi image partitions

set -e

MOUNT_POINT="$1"

if [ -z "$MOUNT_POINT" ]; then
    echo "Usage: $0 <mount-point>"
    exit 1
fi

if [ $EUID -ne 0 ]; then
    echo "Error: This script must be run as root"
    exit 1
fi

if [ ! -d "$MOUNT_POINT" ]; then
    echo "Error: Mount point not found: $MOUNT_POINT"
    exit 1
fi

# Remove qemu static if present
if [ -f "$MOUNT_POINT/usr/bin/qemu-aarch64-static" ]; then
    echo "Removing qemu-aarch64-static..."
    rm -f "$MOUNT_POINT/usr/bin/qemu-aarch64-static"
fi

# Unmount any chroot bind mounts
for mount in proc sys dev/pts dev; do
    if mountpoint -q "$MOUNT_POINT/$mount" 2>/dev/null; then
        echo "Unmounting $MOUNT_POINT/$mount..."
        umount "$MOUNT_POINT/$mount" || true
    fi
done

# Unmount boot partition
if mountpoint -q "$MOUNT_POINT/boot/firmware" 2>/dev/null; then
    echo "Unmounting boot partition..."
    umount "$MOUNT_POINT/boot/firmware"
fi

# Unmount root partition
if mountpoint -q "$MOUNT_POINT" 2>/dev/null; then
    echo "Unmounting root partition..."
    umount "$MOUNT_POINT"
fi

# Remove loop device mappings
LOOP_FILE="${MOUNT_POINT}/../loop_device"
if [ -f "$LOOP_FILE" ]; then
    LOOP_DEV=$(cat "$LOOP_FILE")
    echo "Removing loop device mappings for $LOOP_DEV..."
    kpartx -d "$LOOP_DEV"
    losetup -d "$LOOP_DEV"
    rm -f "$LOOP_FILE"
fi

echo "Image unmounted successfully."