#!/bin/bash
# BeatPi Image Customization Script
# This script runs in the context of the mounted image to apply customizations

set -e

MOUNT_ROOT="$1"

if [ -z "$MOUNT_ROOT" ]; then
    echo "Usage: $0 <mount-root>"
    exit 1
fi

if [ ! -d "$MOUNT_ROOT" ]; then
    echo "Error: Mount root not found: $MOUNT_ROOT"
    exit 1
fi

log() {
    echo "[CUSTOMIZE] $1"
}

error() {
    echo "[ERROR] $1" >&2
    exit 1
}

# Copy Spotify Kids Manager files if they exist
copy_spotify_kids_manager() {
    log "Looking for Spotify Kids Manager files..."
    
    # Check for the application in the parent directory
    local SKM_SOURCE="../spotify-kids-manager"
    
    if [ -d "$SKM_SOURCE" ]; then
        log "Found Spotify Kids Manager at $SKM_SOURCE"
        log "Copying application files..."
        
        # Create destination directory
        mkdir -p "${MOUNT_ROOT}/opt/spotify-kids-manager-files"
        
        # Copy application files (excluding node_modules and .git)
        rsync -av --exclude=node_modules --exclude=.git \
              "$SKM_SOURCE/" "${MOUNT_ROOT}/opt/spotify-kids-manager-files/"
        
        log "Spotify Kids Manager files copied successfully"
    else
        log "Warning: Spotify Kids Manager not found at $SKM_SOURCE"
        log "The application will need to be installed manually after first boot"
    fi
}

# Configure boot settings
configure_boot() {
    log "Configuring boot settings..."
    
    # Enable HDMI output
    if [ -f "${MOUNT_ROOT}/boot/firmware/config.txt" ]; then
        cat >> "${MOUNT_ROOT}/boot/firmware/config.txt" << 'EOF'

# BeatPi Configuration
# Enable HDMI audio
dtparam=audio=on
hdmi_drive=2

# GPU memory split (needed for Chromium)
gpu_mem=128

# Enable touch screen support
dtoverlay=vc4-kms-v3d

# Disable splash screen
disable_splash=1

# Boot faster
boot_delay=0

EOF
        log "Boot configuration updated"
    else
        log "Warning: config.txt not found"
    fi
    
    # Configure cmdline for quiet boot
    if [ -f "${MOUNT_ROOT}/boot/firmware/cmdline.txt" ]; then
        sed -i 's/$/ quiet loglevel=3/' "${MOUNT_ROOT}/boot/firmware/cmdline.txt"
        log "Command line updated for quiet boot"
    fi
}

# Setup systemd service for firstboot
setup_firstboot_service() {
    log "Setting up firstboot service..."
    
    cat > "${MOUNT_ROOT}/etc/systemd/system/beatpi-firstboot.service" << 'EOF'
[Unit]
Description=BeatPi First Boot Setup
After=network-online.target
Wants=network-online.target
ConditionPathExists=!/boot/firmware/beatpi_firstboot_done

[Service]
Type=oneshot
ExecStart=/opt/firstboot/setup.sh
RemainAfterExit=yes
StandardOutput=journal+console
StandardError=journal+console

[Install]
WantedBy=multi-user.target
EOF
    
    # Enable the service in the image
    chroot "$MOUNT_ROOT" systemctl enable beatpi-firstboot.service || true
    
    log "Firstboot service configured"
}

# Pre-configure some system settings
preconfigure_system() {
    log "Pre-configuring system settings..."
    
    # Create pi user if using older image that doesn't have it
    if ! grep -q "^pi:" "${MOUNT_ROOT}/etc/passwd"; then
        log "Creating pi user..."
        chroot "$MOUNT_ROOT" useradd -m -G sudo,audio,video,bluetooth -s /bin/bash pi || true
        echo "pi:raspberry" | chroot "$MOUNT_ROOT" chpasswd || true
    fi
    
    # Enable SSH by default (Pi Imager will override if configured differently)
    touch "${MOUNT_ROOT}/boot/firmware/ssh"
    
    # Configure locale
    echo "en_US.UTF-8 UTF-8" > "${MOUNT_ROOT}/etc/locale.gen"
    chroot "$MOUNT_ROOT" locale-gen || true
    echo "LANG=en_US.UTF-8" > "${MOUNT_ROOT}/etc/default/locale"
    
    # Set hostname
    echo "beatpi" > "${MOUNT_ROOT}/etc/hostname"
    cat > "${MOUNT_ROOT}/etc/hosts" << 'EOF'
127.0.0.1       localhost
127.1.1.1       beatpi

# IPv6
::1             localhost ip6-localhost ip6-loopback
ff02::1         ip6-allnodes
ff02::2         ip6-allrouters
EOF
    
    log "System pre-configuration complete"
}

# Create placeholder directories
create_directories() {
    log "Creating required directories..."
    
    mkdir -p "${MOUNT_ROOT}/opt/spotify-kids-manager"
    mkdir -p "${MOUNT_ROOT}/var/log"
    mkdir -p "${MOUNT_ROOT}/home/pi/.config"
    
    log "Directories created"
}

# Clean up unnecessary files to save space
cleanup_image() {
    log "Cleaning up image to save space..."
    
    # Clean apt cache
    chroot "$MOUNT_ROOT" apt-get clean || true
    rm -rf "${MOUNT_ROOT}/var/lib/apt/lists/"* || true
    
    # Remove documentation to save space (optional)
    # rm -rf "${MOUNT_ROOT}/usr/share/doc/"*
    # rm -rf "${MOUNT_ROOT}/usr/share/man/"*
    
    # Clear logs
    find "${MOUNT_ROOT}/var/log" -type f -exec truncate -s 0 {} \; 2>/dev/null || true
    
    log "Cleanup complete"
}

# Main customization process
main() {
    log "Starting image customization for: $MOUNT_ROOT"
    
    # Run customization steps
    copy_spotify_kids_manager
    configure_boot
    create_directories
    preconfigure_system
    setup_firstboot_service
    cleanup_image
    
    log "Image customization completed successfully!"
}

# Run main function
main