# BeatPi - Music Player for Kids 🎵

A ready-to-use Raspberry Pi image that transforms your Pi into a kid-friendly music streaming kiosk.

## Download

**Latest Release:** [BeatPi v1.2.0](https://github.com/socialoutcast/BeatPI/releases/latest)

Download the `.img.xz` file from the releases page.

## Installation with Raspberry Pi Imager

### Requirements
- Raspberry Pi 3B+ or newer (Pi 4 recommended)
- 8GB+ SD card
- **Network connection (Ethernet or WiFi) - REQUIRED before first boot**
- Proper power supply (5V 3A minimum)

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

## First Boot Setup

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

### Complete Setup
1. From any computer on the same network, open a web browser
2. Navigate to the HTTPS URL shown on your Pi's screen
3. Accept the security certificate warning (it's a self-signed certificate)
4. Login with:
   - Username: `admin`
   - Password: `changeme`
5. Follow the on-screen instructions to:
   - Change the admin password
   - Configure Spotify
   - Set up parental controls

## Troubleshooting

### No Display on Screen
- Initial setup takes 2-3 minutes
- Check power supply (low voltage indicator in admin panel)
- Verify HDMI connection

### Can't Access Admin Panel
- Ensure your computer is on the same network as the Pi
- Try using the IP address directly: `https://<IP-ADDRESS>`
- Accept the self-signed certificate warning

### Network Issues
- Ethernet is most reliable for initial setup
- If using WiFi, double-check credentials in Pi Imager
- Country code must match your location for WiFi to work

## Support

Report issues at: https://github.com/socialoutcast/BeatPI/issues

## License

MIT License - See [LICENSE](LICENSE) file for details.