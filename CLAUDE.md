# CLAUDE.md

This file provides guidance to Claude Code when working with the BeatPi project.

## Project Overview

BeatPi is a custom Raspberry Pi OS image builder that creates a pre-configured music streaming kiosk for kids. It packages the Spotify Kids Manager application into a ready-to-flash Pi OS image.

## Key Features

- Pre-installed Spotify Kids Manager web application
- Automatic kiosk mode on boot
- Touch screen support
- Bluetooth audio configuration
- Web-based admin panel (HTTPS)
- Parental controls for music content
- Works with Raspberry Pi Imager custom settings

## Project Structure

```
beatpi/
├── CLAUDE.md           # This file
├── README.md          # User documentation
├── .gitignore         # Git ignore rules
├── firstboot/         # Scripts that run on first boot
├── image-builder/     # Image building tools
├── scripts/           # Helper scripts
├── images/            # Downloaded Pi OS images
├── work/              # Working directory for image modification
└── output/            # Final built images
```

## Build Process

1. Download latest Raspberry Pi OS 64-bit Lite image
2. Extract and mount the image
3. Install Spotify Kids Manager application
4. Configure firstboot script for Pi Imager settings
5. Set up systemd services
6. Configure auto-login and kiosk mode
7. Package and compress final image

## Important Notes

- This project builds on top of Raspberry Pi OS Bookworm (64-bit)
- The image should work with Pi Imager's custom settings (username, password, WiFi)
- All Spotify Kids Manager files come from ../spotify-kids-manager/
- The firstboot script handles initial setup using Pi Imager configured settings
- Default admin panel credentials: admin/changeme (user should change)

## Commands

```bash
# Build the image
./build-image.sh

# Clean build artifacts
./clean.sh

# Test image in QEMU (if available)
./test-image.sh
```

## Key Files

- `firstboot/setup.sh` - Runs on first boot to configure the system
- `image-builder/build.sh` - Main build script
- `scripts/mount-image.sh` - Helper to mount Pi image partitions
- `scripts/customize-image.sh` - Applies customizations to mounted image

## Dependencies

Building requires:
- `xz-utils` - For extracting compressed images
- `parted` - For partition management
- `kpartx` - For mapping image partitions
- `qemu-user-static` - For ARM emulation during build
- Root/sudo access for mounting images

## Security Considerations

- The image includes pre-configured SSL certificates (self-signed)
- Admin panel password should be changed on first login
- Spotify authentication required before music playback
- All services run under dedicated user accounts

## Testing

After building, the image can be:
1. Flashed to SD card with Raspberry Pi Imager
2. Tested in QEMU ARM emulation
3. Verified on actual Raspberry Pi hardware

## Release Process

1. Build the image with `./build-image.sh`
2. Test thoroughly on Pi hardware
3. Compress with xz: `xz -9 output/beatpi-*.img`
4. Generate checksums: `sha256sum output/beatpi-*.img.xz`
5. Create GitHub release with image and checksums