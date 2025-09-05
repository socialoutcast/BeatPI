#!/bin/bash
set -e

# BeatPi Image Builder
# Builds a custom Raspberry Pi OS image with Spotify Kids Manager

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK_DIR="${SCRIPT_DIR}/work"
IMAGES_DIR="${SCRIPT_DIR}/images"
OUTPUT_DIR="${SCRIPT_DIR}/output"
IMAGE_BUILDER_DIR="${SCRIPT_DIR}/image-builder"

# Configuration
RPI_OS_URL="https://downloads.raspberrypi.com/raspios_lite_arm64/images/raspios_lite_arm64-2024-11-19/2024-11-19-raspios-bookworm-arm64-lite.img.xz"
IMAGE_NAME="beatpi-$(date +%Y%m%d).img"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[$(date '+%H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
    exit 1
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root"
    fi
}

# Check required tools
check_dependencies() {
    log "Checking dependencies..."
    
    local missing_deps=()
    
    for cmd in parted kpartx losetup qemu-aarch64-static xz wget; do
        if ! command -v $cmd &> /dev/null; then
            missing_deps+=($cmd)
        fi
    done
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        error "Missing dependencies: ${missing_deps[*]}\nInstall with: apt-get install parted kpartx qemu-user-static xz-utils wget"
    fi
    
    log "All dependencies satisfied"
}

# Clean up any previous work
cleanup_work() {
    log "Cleaning up previous work directory..."
    
    # Unmount any mounted filesystems
    if mountpoint -q "${WORK_DIR}/mnt/boot/firmware" 2>/dev/null; then
        umount "${WORK_DIR}/mnt/boot/firmware" || true
    fi
    
    if mountpoint -q "${WORK_DIR}/mnt" 2>/dev/null; then
        umount "${WORK_DIR}/mnt" || true
    fi
    
    # Remove loop devices
    if [ -f "${WORK_DIR}/loop_device" ]; then
        local loop_dev=$(cat "${WORK_DIR}/loop_device")
        kpartx -d "$loop_dev" 2>/dev/null || true
        losetup -d "$loop_dev" 2>/dev/null || true
    fi
    
    rm -rf "${WORK_DIR}"
    mkdir -p "${WORK_DIR}/mnt"
}

# Download Raspberry Pi OS image
download_image() {
    log "Downloading Raspberry Pi OS image..."
    
    mkdir -p "${IMAGES_DIR}"
    
    local image_file="${IMAGES_DIR}/$(basename ${RPI_OS_URL})"
    local extracted_image="${IMAGES_DIR}/$(basename ${RPI_OS_URL} .xz)"
    
    if [ ! -f "$extracted_image" ]; then
        if [ ! -f "$image_file" ]; then
            wget -c "$RPI_OS_URL" -O "$image_file" || error "Failed to download image"
        fi
        
        log "Extracting image..."
        xz -d -k "$image_file" || error "Failed to extract image"
    else
        log "Using existing image: $extracted_image"
    fi
    
    echo "$extracted_image"
}

# Copy and prepare working image
prepare_working_image() {
    local source_image="$1"
    local working_image="${WORK_DIR}/working.img"
    
    log "Copying image to working directory..."
    cp "$source_image" "$working_image" || error "Failed to copy image"
    
    # Expand image to add space for our software
    log "Expanding image size..."
    dd if=/dev/zero bs=1M count=1024 >> "$working_image" 2>/dev/null
    
    # Fix partition table
    log "Fixing partition table..."
    parted -s "$working_image" resizepart 2 100%
    
    echo "$working_image"
}

# Mount the image
mount_image() {
    local image_file="$1"
    
    log "Setting up loop device..."
    local loop_dev=$(losetup -f --show "$image_file")
    echo "$loop_dev" > "${WORK_DIR}/loop_device"
    
    log "Mapping partitions..."
    kpartx -a "$loop_dev"
    sleep 2
    
    # Find partition devices
    local boot_part="/dev/mapper/$(basename $loop_dev)p1"
    local root_part="/dev/mapper/$(basename $loop_dev)p2"
    
    # Check and resize filesystem
    log "Checking and resizing filesystem..."
    e2fsck -f -y "$root_part" || true
    resize2fs "$root_part" || warning "Failed to resize filesystem"
    
    # Mount partitions
    log "Mounting partitions..."
    mount "$root_part" "${WORK_DIR}/mnt" || error "Failed to mount root partition"
    mount "$boot_part" "${WORK_DIR}/mnt/boot/firmware" || error "Failed to mount boot partition"
    
    # Copy qemu static for ARM emulation
    cp /usr/bin/qemu-aarch64-static "${WORK_DIR}/mnt/usr/bin/" || error "Failed to copy qemu-static"
}

# Customize the image
customize_image() {
    log "Customizing image..."
    
    # Mount necessary filesystems for chroot
    mount -t proc proc "${WORK_DIR}/mnt/proc"
    mount -t sysfs sys "${WORK_DIR}/mnt/sys"
    mount -o bind /dev "${WORK_DIR}/mnt/dev"
    mount -o bind /dev/pts "${WORK_DIR}/mnt/dev/pts"
    
    # Copy firstboot script
    log "Installing firstboot script..."
    cp -r "${SCRIPT_DIR}/firstboot" "${WORK_DIR}/mnt/opt/"
    chmod +x "${WORK_DIR}/mnt/opt/firstboot/setup.sh"
    
    # Run customization script
    "${IMAGE_BUILDER_DIR}/customize-image.sh" "${WORK_DIR}/mnt" || error "Customization failed"
    
    # Cleanup chroot mounts
    umount "${WORK_DIR}/mnt/dev/pts" || true
    umount "${WORK_DIR}/mnt/dev" || true
    umount "${WORK_DIR}/mnt/sys" || true
    umount "${WORK_DIR}/mnt/proc" || true
}

# Unmount and finalize image
finalize_image() {
    log "Finalizing image..."
    
    # Remove qemu static
    rm -f "${WORK_DIR}/mnt/usr/bin/qemu-aarch64-static"
    
    # Unmount partitions
    umount "${WORK_DIR}/mnt/boot/firmware" || warning "Failed to unmount boot partition"
    umount "${WORK_DIR}/mnt" || warning "Failed to unmount root partition"
    
    # Remove loop device mappings
    local loop_dev=$(cat "${WORK_DIR}/loop_device")
    kpartx -d "$loop_dev"
    losetup -d "$loop_dev"
    
    # Move final image to output
    mkdir -p "${OUTPUT_DIR}"
    mv "${WORK_DIR}/working.img" "${OUTPUT_DIR}/${IMAGE_NAME}"
    
    log "Image created: ${OUTPUT_DIR}/${IMAGE_NAME}"
}

# Main build process
main() {
    log "Starting BeatPi image build..."
    
    check_root
    check_dependencies
    cleanup_work
    
    # Download and prepare image
    local base_image=$(download_image)
    local working_image=$(prepare_working_image "$base_image")
    
    # Mount and customize
    mount_image "$working_image"
    customize_image
    finalize_image
    
    # Generate checksum
    log "Generating checksum..."
    (cd "${OUTPUT_DIR}" && sha256sum "${IMAGE_NAME}" > "${IMAGE_NAME}.sha256")
    
    log "Build complete!"
    log "Image: ${OUTPUT_DIR}/${IMAGE_NAME}"
    log "Flash with: sudo dd if=${OUTPUT_DIR}/${IMAGE_NAME} of=/dev/sdX bs=4M status=progress"
}

# Run main function
main "$@"