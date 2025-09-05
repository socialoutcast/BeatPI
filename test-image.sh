#!/bin/bash
# BeatPi QEMU Test Script
# Tests the built image in QEMU ARM emulation

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUTPUT_DIR="${SCRIPT_DIR}/output"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[TEST]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
    exit 1
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check dependencies
check_dependencies() {
    log "Checking QEMU installation..."
    
    if ! command -v qemu-system-aarch64 &> /dev/null; then
        error "qemu-system-aarch64 not found. Install with: apt-get install qemu-system-arm"
    fi
    
    log "QEMU is installed"
}

# Find the latest image
find_image() {
    local latest_image=$(ls -t "${OUTPUT_DIR}"/beatpi-*.img 2>/dev/null | head -n1)
    
    if [ -z "$latest_image" ]; then
        error "No BeatPi image found in ${OUTPUT_DIR}/"
    fi
    
    echo "$latest_image"
}

# Extract kernel and DTB from image
extract_boot_files() {
    local image_file="$1"
    local temp_dir="${SCRIPT_DIR}/work/qemu-boot"
    
    log "Extracting boot files from image..."
    
    mkdir -p "$temp_dir"
    
    # Mount the image to extract kernel and DTB
    if [[ $EUID -ne 0 ]]; then
        warning "Not running as root - using alternative extraction method"
        # Try to extract without mounting (less reliable)
        error "Please run as root to extract boot files from the image"
    fi
    
    # Create loop device and mount
    local loop_dev=$(losetup -f --show "$image_file")
    kpartx -a "$loop_dev"
    sleep 2
    
    local boot_part="/dev/mapper/$(basename $loop_dev)p1"
    
    # Mount boot partition
    mkdir -p "$temp_dir/mount"
    mount "$boot_part" "$temp_dir/mount"
    
    # Copy kernel and DTB
    cp "$temp_dir/mount/kernel8.img" "$temp_dir/" 2>/dev/null || \
        cp "$temp_dir/mount/vmlinuz" "$temp_dir/kernel8.img" 2>/dev/null || \
        warning "Could not find kernel image"
    
    cp "$temp_dir/mount/bcm2710-rpi-3-b-plus.dtb" "$temp_dir/" 2>/dev/null || \
        warning "Could not find device tree blob"
    
    # Unmount and cleanup
    umount "$temp_dir/mount"
    kpartx -d "$loop_dev"
    losetup -d "$loop_dev"
    
    log "Boot files extracted"
}

# Run QEMU
run_qemu() {
    local image_file="$1"
    local temp_dir="${SCRIPT_DIR}/work/qemu-boot"
    
    log "Starting QEMU emulation..."
    log "Press Ctrl-A X to exit QEMU"
    
    # Basic QEMU command for Raspberry Pi 3B+ emulation
    qemu-system-aarch64 \
        -M raspi3b \
        -cpu cortex-a72 \
        -m 1G \
        -smp 4 \
        -drive file="$image_file",format=raw,if=sd \
        -netdev user,id=net0,hostfwd=tcp::5022-:22,hostfwd=tcp::8080-:80,hostfwd=tcp::8443-:443,hostfwd=tcp::3000-:3000 \
        -device usb-net,netdev=net0 \
        -nographic \
        -serial mon:stdio \
        || true
    
    # Alternative command if the above doesn't work
    # qemu-system-aarch64 \
    #     -M virt \
    #     -cpu cortex-a72 \
    #     -m 1G \
    #     -smp 4 \
    #     -kernel "$temp_dir/kernel8.img" \
    #     -drive file="$image_file",format=raw,if=virtio \
    #     -netdev user,id=net0,hostfwd=tcp::5022-:22 \
    #     -device virtio-net-device,netdev=net0 \
    #     -nographic \
    #     -append "console=ttyAMA0 root=/dev/vda2 rootfstype=ext4 rw"
}

# Simple test without full QEMU (just check image integrity)
simple_test() {
    local image_file="$1"
    
    log "Running simple image integrity test..."
    
    # Check image file
    if [ ! -f "$image_file" ]; then
        error "Image file not found: $image_file"
    fi
    
    local size=$(stat -c%s "$image_file")
    local size_mb=$((size / 1024 / 1024))
    log "Image size: ${size_mb}MB"
    
    # Check if image has valid partition table
    if command -v fdisk &> /dev/null; then
        log "Checking partition table..."
        fdisk -l "$image_file" | grep -E "^Device|^$image_file"
    fi
    
    log "Basic image checks passed"
}

# Display connection information
show_connection_info() {
    echo
    echo "============================================"
    echo "BeatPi QEMU Test Environment"
    echo "============================================"
    echo "SSH:          ssh -p 5022 pi@localhost"
    echo "HTTP:         http://localhost:8080"
    echo "HTTPS:        https://localhost:8443"
    echo "App Direct:   http://localhost:3000"
    echo "Exit QEMU:    Press Ctrl-A X"
    echo "============================================"
    echo
}

# Main test function
main() {
    log "Starting BeatPi image test..."
    
    # Find image to test
    local image_file="${1:-$(find_image)}"
    log "Testing image: $image_file"
    
    # Run simple test first
    simple_test "$image_file"
    
    # Check if we should run full QEMU test
    if [ "$2" == "--qemu" ] || [ "$1" == "--qemu" ]; then
        check_dependencies
        
        if [[ $EUID -eq 0 ]]; then
            extract_boot_files "$image_file"
        fi
        
        show_connection_info
        run_qemu "$image_file"
    else
        log "Image validation complete!"
        log "To test in QEMU emulator, run: sudo $0 --qemu"
    fi
}

# Show usage
if [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
    echo "Usage: $0 [image-file] [--qemu]"
    echo "  Test a BeatPi image file"
    echo ""
    echo "Options:"
    echo "  --qemu    Run full QEMU emulation test (requires root)"
    echo ""
    echo "If no image file is specified, the latest image in output/ will be used"
    exit 0
fi

# Run main function
main "$@"