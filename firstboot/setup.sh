#!/bin/bash
# BeatPi First Boot Setup Script
# This runs on first boot to configure the system using Raspberry Pi Imager settings

set -e

LOGFILE="/var/log/beatpi-firstboot.log"
FIRSTBOOT_FLAG="/boot/firmware/beatpi_firstboot_done"

# Redirect output to log file
exec 1> >(tee -a "$LOGFILE")
exec 2>&1

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

error() {
    log "ERROR: $1"
    exit 1
}

# Check if this is first boot
if [ -f "$FIRSTBOOT_FLAG" ]; then
    log "First boot already completed, exiting"
    exit 0
fi

log "Starting BeatPi first boot configuration..."

# Wait for network to be available
wait_for_network() {
    log "Waiting for network connection..."
    local max_attempts=30
    local attempt=0
    
    while [ $attempt -lt $max_attempts ]; do
        if ping -c 1 -W 2 8.8.8.8 &> /dev/null; then
            log "Network is available"
            return 0
        fi
        attempt=$((attempt + 1))
        sleep 2
    done
    
    log "Warning: Network not available after ${max_attempts} attempts"
    return 1
}

# Configure system settings
configure_system() {
    log "Configuring system settings..."
    
    # Enable SSH (should already be done by Pi Imager)
    systemctl enable ssh
    systemctl start ssh
    
    # Set timezone
    timedatectl set-timezone America/New_York || true
    
    # Configure audio for HDMI and Bluetooth
    log "Configuring audio..."
    cat > /etc/asound.conf << 'EOF'
pcm.!default {
    type hw
    card 0
}

ctl.!default {
    type hw
    card 0
}
EOF
    
    # Enable Bluetooth
    systemctl enable bluetooth
    systemctl start bluetooth
}

# Install required packages
install_packages() {
    log "Installing required packages..."
    
    wait_for_network || log "Continuing without network..."
    
    # Update package lists
    apt-get update || log "Failed to update package lists"
    
    # Install packages
    PACKAGES=(
        chromium-browser
        xorg
        xinit
        x11-xserver-utils
        unclutter
        nginx
        nodejs
        npm
        bluetooth
        bluez
        pulseaudio
        pulseaudio-module-bluetooth
        libgles2
        libegl1
        libgl1-mesa-dri
        mesa-utils
        matchbox-window-manager
    )
    
    for package in "${PACKAGES[@]}"; do
        log "Installing $package..."
        apt-get install -y "$package" || log "Failed to install $package"
    done
}

# Setup Spotify Kids Manager
setup_spotify_kids_manager() {
    log "Setting up Spotify Kids Manager..."
    
    # Create application directory
    mkdir -p /opt/spotify-kids-manager
    
    # Check if the app files exist (should be copied during image build)
    if [ -d "/opt/spotify-kids-manager-files" ]; then
        log "Copying Spotify Kids Manager files..."
        cp -r /opt/spotify-kids-manager-files/* /opt/spotify-kids-manager/
        rm -rf /opt/spotify-kids-manager-files
    else
        log "Warning: Spotify Kids Manager files not found, will need manual installation"
    fi
    
    # Install Node dependencies if package.json exists
    if [ -f "/opt/spotify-kids-manager/package.json" ]; then
        log "Installing Node.js dependencies..."
        cd /opt/spotify-kids-manager
        npm install --production || log "Failed to install npm dependencies"
    fi
    
    # Create systemd service for the app
    cat > /etc/systemd/system/spotify-kids-manager.service << 'EOF'
[Unit]
Description=Spotify Kids Manager
After=network.target

[Service]
Type=simple
User=pi
WorkingDirectory=/opt/spotify-kids-manager
ExecStart=/usr/bin/node /opt/spotify-kids-manager/server.js
Restart=always
RestartSec=10
Environment="NODE_ENV=production"
Environment="PORT=3000"

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
    systemctl enable spotify-kids-manager
}

# Configure kiosk mode
setup_kiosk_mode() {
    log "Setting up kiosk mode..."
    
    # Create kiosk user if it doesn't exist
    if ! id -u kiosk >/dev/null 2>&1; then
        useradd -m -s /bin/bash kiosk
        usermod -a -G audio,video,bluetooth kiosk
    fi
    
    # Get the configured user from Pi Imager (or use default)
    CONFIG_USER=$(grep "^[^:]*:1000:" /etc/passwd | cut -d: -f1)
    if [ -z "$CONFIG_USER" ]; then
        CONFIG_USER="pi"
    fi
    
    # Create autostart script
    mkdir -p /home/$CONFIG_USER/.config/autostart
    
    cat > /home/$CONFIG_USER/start-kiosk.sh << 'EOF'
#!/bin/bash

# Wait for services to start
sleep 10

# Disable screen blanking
xset s off
xset -dpms
xset s noblank

# Hide cursor after 3 seconds of inactivity
unclutter -idle 3 &

# Start window manager
matchbox-window-manager -use_titlebar no &

# Wait for window manager
sleep 2

# Start Chromium in kiosk mode
chromium-browser \
    --kiosk \
    --noerrdialogs \
    --disable-infobars \
    --disable-session-crashed-bubble \
    --disable-features=TranslateUI \
    --overscroll-history-navigation=0 \
    --disable-pinch \
    --check-for-update-interval=31536000 \
    http://localhost:3000
EOF
    
    chmod +x /home/$CONFIG_USER/start-kiosk.sh
    chown $CONFIG_USER:$CONFIG_USER /home/$CONFIG_USER/start-kiosk.sh
    
    # Configure auto-login and auto-start X
    mkdir -p /etc/systemd/system/getty@tty1.service.d/
    cat > /etc/systemd/system/getty@tty1.service.d/autologin.conf << EOF
[Service]
ExecStart=
ExecStart=-/sbin/agetty --autologin $CONFIG_USER --noclear %I \$TERM
EOF
    
    # Add xinit to user's .profile
    cat >> /home/$CONFIG_USER/.profile << 'EOF'

# Start X automatically on tty1
if [ -z "$DISPLAY" ] && [ "$XDG_VTNR" = 1 ]; then
    exec startx /home/$(whoami)/start-kiosk.sh
fi
EOF
    
    chown $CONFIG_USER:$CONFIG_USER /home/$CONFIG_USER/.profile
}

# Configure nginx for admin panel
setup_nginx() {
    log "Configuring nginx for admin panel..."
    
    # Generate self-signed certificate
    mkdir -p /etc/nginx/ssl
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/nginx/ssl/beatpi.key \
        -out /etc/nginx/ssl/beatpi.crt \
        -subj "/C=US/ST=State/L=City/O=BeatPi/CN=beatpi.local"
    
    # Configure nginx
    cat > /etc/nginx/sites-available/beatpi-admin << 'EOF'
server {
    listen 80;
    server_name _;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    server_name _;
    
    ssl_certificate /etc/nginx/ssl/beatpi.crt;
    ssl_certificate_key /etc/nginx/ssl/beatpi.key;
    
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
    
    location /admin {
        auth_basic "Admin Panel";
        auth_basic_user_file /etc/nginx/.htpasswd;
        proxy_pass http://localhost:3000/admin;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
EOF
    
    # Create default admin credentials (admin:changeme)
    echo 'admin:$apr1$d3WFz0Wu$VgCEaKXJC3TTGZCxJvBZG/' > /etc/nginx/.htpasswd
    
    # Enable site
    ln -sf /etc/nginx/sites-available/beatpi-admin /etc/nginx/sites-enabled/
    rm -f /etc/nginx/sites-enabled/default
    
    systemctl enable nginx
    systemctl restart nginx || true
}

# Setup firewall
setup_firewall() {
    log "Configuring firewall..."
    
    # Install ufw if not present
    apt-get install -y ufw || true
    
    # Configure firewall rules
    ufw --force enable
    ufw default deny incoming
    ufw default allow outgoing
    ufw allow ssh
    ufw allow 80/tcp
    ufw allow 443/tcp
    ufw allow 3000/tcp
    
    log "Firewall configured"
}

# Main setup
main() {
    log "BeatPi First Boot Setup Starting..."
    
    # Run setup steps
    configure_system
    install_packages
    setup_spotify_kids_manager
    setup_kiosk_mode
    setup_nginx
    setup_firewall
    
    # Create completion flag
    touch "$FIRSTBOOT_FLAG"
    
    log "First boot setup completed successfully!"
    log "System will reboot in 10 seconds..."
    
    # Schedule reboot
    sleep 10
    reboot
}

# Run main function
main