# BeatPi 🎵

A pre-configured Raspberry Pi OS image for creating a kid-friendly music streaming kiosk.

## What is BeatPi?

BeatPi transforms your Raspberry Pi into a dedicated music player kiosk with:
- Touch-screen interface
- Parental controls
- Bluetooth speaker support
- Web-based admin panel
- Support for music streaming services
- Auto-start kiosk mode

## Quick Start

### Option 1: Pre-built Image (Coming Soon)
1. Download BeatPi image
2. Flash with Raspberry Pi Imager
3. Configure WiFi and user in Imager settings
4. Boot and enjoy!

### Option 2: Install on Existing Pi OS
```bash
curl -fsSL https://github.com/yourusername/beatpi/raw/main/install.sh | sudo bash
```

## Features

- 🎵 **Music Streaming** - Connect to your favorite streaming services
- 👶 **Kid-Friendly** - Simple interface, parental controls
- 🔊 **Bluetooth Audio** - Connect to any Bluetooth speaker
- 📱 **Touch Support** - Works with touchscreen displays
- 🌐 **Web Admin** - Configure from any device on your network
- 🚀 **Auto-Start** - Boots directly into music player

## Requirements

- Raspberry Pi 3/4/5 (64-bit recommended)
- 8GB+ SD card
- Internet connection
- Bluetooth speaker (optional)
- Touchscreen display (optional)

## Configuration

After installation, access the admin panel at:
```
https://<your-pi-ip>
```

Default credentials:
- Username: `admin`
- Password: `changeme`

## Building Custom Image

See [BUILD.md](BUILD.md) for instructions on creating your own BeatPi image.

## License

MIT License - See [LICENSE](LICENSE) file for details.

## Disclaimer

This project is not affiliated with Spotify or any other music streaming service.