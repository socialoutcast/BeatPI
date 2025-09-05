# BeatPi v1.1.0 Release Notes

## Release Date: September 5, 2025

### What's New

#### 🔋 Power Monitoring
- **Low Voltage Detection**: Admin panel now displays warnings when power supply is insufficient
- Real-time monitoring of undervoltage and temperature throttling
- Helps diagnose touchscreen and system stability issues
- Clear indicators in dashboard when power issues are detected

#### 🌐 Improved Setup Experience  
- **Network-Aware Setup Screen**: Player app automatically detects network connectivity
- Displays your device's IP address prominently (non-clickable) for easy access from another device
- Clear instructions for accessing admin panel from computer or phone
- Step-by-step network setup guide when no connection is detected
- Automatic refresh while waiting for network connection

#### 🔧 Enhanced First Boot Configuration
- **Better Service Configuration**: Fixed all service startup issues
- Player now runs on correct port (5000) matching single-user installer
- Proper environment variables for all services
- Automatic npm dependency installation

#### 🎵 Audio & Bluetooth Improvements
- **Professional Audio Setup**: Comprehensive PulseAudio configuration
- Bluetooth A2DP profile for high-quality audio streaming
- Disabled conflicting services (PipeWire, BlueALSA)
- User-specific audio configuration files
- Better Bluetooth device pairing experience

#### 🖥️ Kiosk Mode Enhancements
- **Touch Support**: Full touch screen support flags in Chromium
- Waits for player service before launching browser
- Improved kiosk launcher script
- Better error handling

### Installation Instructions

1. **Download the image**: `beatpi-20250905.img.xz`
2. **Flash to SD Card** using Raspberry Pi Imager:
   - Select "Use custom" and choose the downloaded image
   - Configure your settings (username, password, WiFi)
   - Flash to your SD card (8GB minimum)
3. **First Boot**:
   - Insert SD card and power on
   - Wait 2-3 minutes for initial setup
   - Screen will show setup instructions with your device's IP
4. **Complete Setup**:
   - From another device, go to the displayed HTTPS URL
   - Accept the security warning (self-signed certificate)
   - Login: username `admin`, password `changeme`
   - Follow Spotify setup instructions

### System Requirements
- Raspberry Pi 3B+ or newer (Pi 4 recommended)
- 8GB+ SD card
- **Proper power supply** (5V 3A minimum for Pi 4)
- Touch screen (optional but recommended)
- Network connection (Ethernet or WiFi)

### Fixed Issues
- ✅ Service failures on first boot
- ✅ Incorrect user detection with Pi Imager
- ✅ Missing npm dependencies
- ✅ Wrong service ports
- ✅ Bluetooth audio conflicts
- ✅ Permission issues with config directories
- ✅ Network setup confusion

### Known Issues
- Self-signed SSL certificate warning (expected - accept to proceed)
- Initial boot may take 2-3 minutes while installing packages

### Checksums
```
SHA256: e0d7170bd3b53520cb9e4e9412733768890a50ef46ca10a39c9378798b420350  beatpi-20250905.img.xz
```

### Support
Report issues at: https://github.com/socialoutcast/BeatPI/issues