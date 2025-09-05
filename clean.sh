#!/bin/bash
# BeatPi Cleanup Script
# Removes build artifacts and temporary files

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[CLEAN]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if running as root (needed for unmounting)
check_root() {
    if [[ $EUID -ne 0 ]]; then
        warning "Not running as root - some cleanup operations may be skipped"
        return 1
    fi
    return 0
}

# Unmount any mounted filesystems
cleanup_mounts() {
    if ! check_root; then
        return
    fi
    
    log "Checking for mounted filesystems..."
    
    local work_dir="${SCRIPT_DIR}/work"
    
    if [ -d "${work_dir}/mnt" ]; then
        # Unmount chroot bind mounts
        for mount in proc sys dev/pts dev; do
            if mountpoint -q "${work_dir}/mnt/$mount" 2>/dev/null; then
                log "Unmounting ${work_dir}/mnt/$mount..."
                umount "${work_dir}/mnt/$mount" || true
            fi
        done
        
        # Unmount boot partition
        if mountpoint -q "${work_dir}/mnt/boot/firmware" 2>/dev/null; then
            log "Unmounting boot partition..."
            umount "${work_dir}/mnt/boot/firmware" || true
        fi
        
        # Unmount root partition
        if mountpoint -q "${work_dir}/mnt" 2>/dev/null; then
            log "Unmounting root partition..."
            umount "${work_dir}/mnt" || true
        fi
    fi
    
    # Clean up loop devices
    if [ -f "${work_dir}/loop_device" ]; then
        local loop_dev=$(cat "${work_dir}/loop_device")
        if [ -n "$loop_dev" ]; then
            log "Removing loop device: $loop_dev"
            kpartx -d "$loop_dev" 2>/dev/null || true
            losetup -d "$loop_dev" 2>/dev/null || true
        fi
    fi
}

# Remove work directory
cleanup_work() {
    log "Removing work directory..."
    rm -rf "${SCRIPT_DIR}/work"
}

# Optional: Remove downloaded images
cleanup_images() {
    read -p "Do you want to remove downloaded Raspberry Pi OS images? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log "Removing downloaded images..."
        rm -rf "${SCRIPT_DIR}/images"
    else
        log "Keeping downloaded images"
    fi
}

# Optional: Remove output images
cleanup_output() {
    if [ -d "${SCRIPT_DIR}/output" ] && [ "$(ls -A ${SCRIPT_DIR}/output)" ]; then
        echo -e "${YELLOW}Warning: The output directory contains built images:${NC}"
        ls -lh "${SCRIPT_DIR}/output/"
        read -p "Do you want to remove built images? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            log "Removing output images..."
            rm -rf "${SCRIPT_DIR}/output"
        else
            log "Keeping output images"
        fi
    fi
}

# Main cleanup
main() {
    log "Starting BeatPi cleanup..."
    
    # Cleanup operations
    cleanup_mounts
    cleanup_work
    cleanup_images
    cleanup_output
    
    # Recreate empty directories
    log "Creating clean directory structure..."
    mkdir -p "${SCRIPT_DIR}/work"
    mkdir -p "${SCRIPT_DIR}/images"
    mkdir -p "${SCRIPT_DIR}/output"
    
    log "Cleanup complete!"
}

# Run main function
main "$@"