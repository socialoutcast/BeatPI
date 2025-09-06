# BeatPi - Music Player for Kids 🎵

**Transform any Raspberry Pi into a secure, parent-controlled Spotify music player designed specifically for children.**

![BeatPi](https://img.shields.io/badge/BeatPi-Music%20Player-1DB954?style=for-the-badge&logo=spotify&logoColor=white)
![License](https://img.shields.io/badge/License-Proprietary-red?style=for-the-badge)

## 🚀 Quick Start - Pre-built Image

**Latest Release:** Coming Soon!

Pre-built images will be available on the releases page. For now, you can build your own image using the source code.

## 📦 Installation with Raspberry Pi Imager

### Requirements
- ✅ **Raspberry Pi 3B+ or newer** (Pi 4 recommended)
- ✅ **8GB+ MicroSD Card**
- ✅ **Network connection** (Ethernet or WiFi) - **REQUIRED before first boot**
- ✅ **Proper power supply** (5V 3A minimum)
- ✅ **Spotify Premium Account** (required for web playback)
- ✅ **Optional: Touchscreen Display** for kiosk mode
- ✅ **Optional: Bluetooth Speakers** for wireless audio

### Step 1: Download Raspberry Pi Imager
Get it from: https://www.raspberrypi.com/software/

### Step 2: Flash the Image
1. Open Raspberry Pi Imager
2. Click **"Choose OS"** → **"Use custom"**
3. Select the downloaded `beatpi-v*.img.xz` file
4. Click **"Choose Storage"** and select your SD card

### Step 3: Configure Settings (IMPORTANT!)
1. Click the **⚙️ (gear icon)** or press `Ctrl+Shift+X`
2. Configure these REQUIRED settings:
   
   **General Tab:**
   - ✅ **Set username and password**
     - Username: Choose any (e.g., "music", "player", "beatpi")
     - Password: Set a secure password
   
   - ✅ **Configure wireless LAN** (if not using Ethernet)
     - SSID: Your WiFi network name
     - Password: Your WiFi password
     - Country: Your WiFi country code (e.g., US, GB, DE)
   
   **Services Tab:**
   - ✅ **Enable SSH** (optional, for troubleshooting)

3. Click **"Save"** to save your settings

### Step 4: Write the Image
1. Click **"Write"**
2. Confirm when prompted
3. Wait for the process to complete (5-10 minutes)

## 🎯 First Boot & Spotify Setup

### Network Connection is REQUIRED
**⚠️ IMPORTANT:** Your Pi MUST have a network connection before powering on:
- **Option A:** Connect an Ethernet cable before booting
- **Option B:** Configure WiFi in Pi Imager settings (Step 3 above)

Without network access, the setup will fail.

### Boot Process
1. Insert the SD card into your Raspberry Pi
2. Ensure network is connected (Ethernet or configured WiFi)
3. Power on the Pi
4. Wait 2-3 minutes for initial setup
5. The screen will display setup instructions with your device's IP address

### Admin Panel Setup
1. From any computer on the same network, open a web browser
2. Navigate to the HTTPS URL shown on your Pi's screen
3. Accept the security certificate warning (it's a self-signed certificate)
4. Login with:
   - Username: `admin`
   - Password: `changeme`
5. **IMPORTANT:** Change the admin password immediately

### Spotify Developer Setup

#### Create Your Spotify App
1. **Go to Spotify Developer Dashboard**
   ```
   https://developer.spotify.com/dashboard
   ```
   - Log in with your Spotify account
   - Click the green **"Create app"** button

2. **Fill in the App Details**
   ```
   App name: BeatPi Music Player
   App description: Kids music player for Raspberry Pi
   Website: (leave blank)
   Redirect URI: (we'll add this next)
   ```

3. **Select APIs**
   - Check: ✅ **Web API**
   - Check: ✅ **Web Playback SDK**
   
4. **Accept Terms and Create**

#### Get Your Credentials
1. In your app's dashboard, copy your **Client ID**
2. Click **"Settings"** → **"View client secret"** and copy it
3. Keep these safe!

#### Configure Redirect URI
1. In your Pi's admin panel, find the redirect URI (shown at top)
2. Copy it (usually `http://YOUR_PI_IP:5001/callback`)
3. In Spotify Dashboard: **Settings** → Add redirect URI → **Save**

#### Complete Setup in Admin Panel
1. Go to **"Spotify Setup"** in the admin panel
2. Enter your Client ID and Client Secret
3. Click **"Save Configuration"**
4. Click **"Authenticate with Spotify"**
5. Log in and authorize the app

## 🌟 Features

### Kid-Friendly Spotify Web Player
- 🎵 **Full Spotify Web Playback SDK** - Complete streaming functionality
- 🎨 **Visual Interface** - Large album artwork and easy-to-read text
- 🎮 **Simple Controls** - Play, pause, skip with large touch targets
- 🔊 **Volume Control** - Visual slider with easy adjustment
- ❤️ **Like Songs** - Save favorite tracks
- 📱 **Responsive Design** - Optimized for touchscreens

### Admin Dashboard
- 🔐 **Secure Login** - Password-protected admin panel (HTTPS)
- 📊 **System Monitoring** - CPU, memory, disk usage, voltage status
- 🎧 **Spotify Integration** - Configure API credentials and authenticate
- 🔵 **Bluetooth Manager** - Scan, pair, connect audio devices
- 📝 **System Logs** - View and download logs
- 🔧 **Service Control** - Restart services and reboot system

### Kiosk Mode
- 🖥️ **Full-Screen Browser** - Chromium in kiosk mode
- 🚀 **Auto-Start on Boot** - Launches automatically
- 🔒 **Locked Interface** - Prevents access to system
- 🍓 **Raspberry Pi Optimized** - Configured for Pi hardware

### Audio & Bluetooth
- 🔊 **PulseAudio Integration** - Professional audio management
- 🎧 **Bluetooth Audio** - High-quality A2DP audio
- 🔄 **Auto-Reconnect** - Reconnects paired devices on boot
- 📡 **Multiple Device Support** - Manage multiple speakers

## 🛠️ Troubleshooting

### No Display on Screen
- Initial setup takes 2-3 minutes
- Check power supply (low voltage indicator in admin panel)
- Verify HDMI connection

### Can't Access Admin Panel
- Ensure your computer is on the same network as the Pi
- Try using the IP address directly: `https://<IP-ADDRESS>`
- Accept the self-signed certificate warning

### Spotify Not Working
1. Verify Premium account is active
2. Check redirect URI matches exactly
3. Re-authenticate in admin panel

### No Audio
1. Check Bluetooth connections in admin panel
2. Ensure PulseAudio service is running
3. Try reconnecting Bluetooth device

### Network Issues
- Ethernet is most reliable for initial setup
- If using WiFi, double-check credentials in Pi Imager
- Country code must match your location for WiFi to work

### Low Voltage Warning
- Use a proper Raspberry Pi power supply (5V 3A minimum)
- Avoid phone chargers - they often can't provide enough current
- Check your power cable - some USB cables have high resistance

## 📁 System Architecture

### Services & Ports
| Service | Port | Description |
|---------|------|-------------|
| spotify-player | 5000 | Web player backend |
| spotify-admin | 5001 | Admin panel |
| nginx | 443 | HTTPS reverse proxy |
| kiosk | - | Chromium browser |

### File Locations
```
/opt/spotify-kids-manager/
├── player/               # Web player backend
├── app.py               # Admin panel
├── static/              # Web assets
└── templates/           # HTML templates
```

## 🔒 Security

- HTTPS encryption for admin panel
- Password-protected administration
- Self-signed SSL certificates
- System isolation with dedicated users
- No shell access in kiosk mode

## 📄 License

**PROPRIETARY SOFTWARE** - Copyright © 2025 SavageIndustries

This is proprietary software. Unauthorized copying, modification, distribution, or reverse engineering is strictly prohibited.

For commercial licensing inquiries, please contact: support@savageindustries.com

## ⚠️ Disclaimers

- NOT affiliated with Spotify AB
- Requires Spotify Premium subscription
- User responsible for Spotify Terms of Service compliance

## Support

Report issues at: https://github.com/socialoutcast/BeatPI/issues

---

**Made with ❤️ for parents who love music and want to share it safely with their kids**