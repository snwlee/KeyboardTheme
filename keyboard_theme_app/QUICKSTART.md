# Multi-Brand Wallpaper App - Quick Start Guide

## Overview

This Flutter app supports multiple brands (flavors) with independent configurations, AdMob IDs, and signing keys.

## Available Flavors

1. **kedehun** - K-POP DEMON HUNTERS (Production ready)
2. **aespa_winter** - Aespa Winter Wallpaper (Needs setup)
3. **aespa_karina** - Aespa Karina Wallpaper (Needs setup)

## Quick Build Commands

### Windows

```bash
# Build Kedehun APK
scripts\build_flavor.bat kedehun apk

# Build Aespa Winter APK
scripts\build_flavor.bat aespa_winter apk

# Build for Play Store (App Bundle)
scripts\build_flavor.bat kedehun appbundle
```

### Linux/Mac

```bash
# Make script executable (first time only)
chmod +x scripts/build_flavor.sh

# Build Kedehun APK
./scripts/build_flavor.sh kedehun apk

# Build Aespa Winter APK
./scripts/build_flavor.sh aespa_winter apk

# Build for Play Store (App Bundle)
./scripts/build_flavor.sh kedehun appbundle
```

### Manual Flutter Commands

```bash
# Kedehun
flutter build apk --release --flavor kedehun --dart-define=FLAVOR=kedehun

# Aespa Winter
flutter build apk --release --flavor aespaWinter --dart-define=FLAVOR=aespa_winter

# Aespa Karina
flutter build apk --release --flavor aespaKarina --dart-define=FLAVOR=aespa_karina
```

## Running in Debug Mode

```bash
# Kedehun
flutter run --flavor kedehun --dart-define=FLAVOR=kedehun

# Aespa Winter
flutter run --flavor aespaWinter --dart-define=FLAVOR=aespa_winter

# Aespa Karina
flutter run --flavor aespaKarina --dart-define=FLAVOR=aespa_karina
```

## Setup New Flavor (Step by Step)

### 1. Update AdMob Configuration

Edit the corresponding file in `lib/config/`:
- `admob_aespa_winter.dart` - Replace test IDs with production IDs
- `admob_aespa_karina.dart` - Replace test IDs with production IDs

### 2. Generate Keystore

```bash
cd android/app/keystore

# For Aespa Winter
keytool -genkey -v -keystore aespa_winter.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# For Aespa Karina
keytool -genkey -v -keystore aespa_karina.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

### 3. Create Keystore Properties

Create `android/key_aespa_winter.properties`:
```properties
storePassword=YOUR_PASSWORD
keyPassword=YOUR_PASSWORD
keyAlias=upload
storeFile=keystore/aespa_winter.jks
```

Create `android/key_aespa_karina.properties`:
```properties
storePassword=YOUR_PASSWORD
keyPassword=YOUR_PASSWORD
keyAlias=upload
storeFile=keystore/aespa_karina.jks
```

### 4. Add App Icons

Place icons in:
- `android/app/src/aespaWinter/res/mipmap-xxxhdpi/ic_launcher.png`
- `android/app/src/aespaKarina/res/mipmap-xxxhdpi/ic_launcher.png`

(Add all densities: mdpi, hdpi, xhdpi, xxhdpi, xxxhdpi)

### 5. Add Brand Logo

Place logos in:
- `assets/aespa_winter/logo.png`
- `assets/aespa_karina/logo.png`

### 6. Build and Test

```bash
# Test debug build
flutter run --flavor aespaWinter --dart-define=FLAVOR=aespa_winter

# Build release APK
scripts/build_flavor.bat aespa_winter apk
```

## Project Structure

```
wallpaper_engine/
├── lib/
│   └── config/
│       ├── admob_config.dart           # Base AdMob config
│       ├── admob_kedehun.dart          # Kedehun AdMob IDs
│       ├── admob_aespa_winter.dart     # Winter AdMob IDs
│       ├── admob_aespa_karina.dart     # Karina AdMob IDs
│       └── app_config.dart             # App configuration
├── android/
│   ├── key_kedehun.properties          # Kedehun signing
│   ├── key_aespa_winter.properties     # Winter signing
│   ├── key_aespa_karina.properties     # Karina signing
│   └── app/
│       ├── build.gradle.kts            # Flavor definitions
│       ├── keystore/                   # JKS files
│       └── src/
│           ├── kedehun/res/           # Kedehun icons
│           ├── aespaWinter/res/       # Winter icons
│           └── aespaKarina/res/       # Karina icons
├── assets/
│   ├── kedehun/                       # Kedehun assets
│   ├── aespa_winter/                  # Winter assets
│   └── aespa_karina/                  # Karina assets
└── scripts/
    ├── build_flavor.sh                # Linux/Mac build script
    └── build_flavor.bat               # Windows build script
```

## Important Security Notes

- **NEVER commit** `.jks` keystore files
- **NEVER commit** `key_*.properties` files with real credentials
- Keep keystores backed up securely
- Use strong, unique passwords

## Common Issues

### "Keystore not found"
- Ensure `android/app/keystore/<flavor>.jks` exists
- Check path in `key_<flavor>.properties`

### "AdMob ads not showing"
- Verify AdMob App ID in `build.gradle.kts`
- Check Ad Unit IDs in config files
- Add test device for testing

### "Wrong app name displayed"
- Check `resValue` in `build.gradle.kts`
- Ensure AndroidManifest uses `@string/app_name`

## Need More Help?

See the comprehensive guide: [MULTI_BRAND_GUIDE.md](./MULTI_BRAND_GUIDE.md)

## Build Output Locations

After successful build:

**APK:**
- `build/app/outputs/flutter-apk/app-kedehun-release.apk`
- `build/app/outputs/flutter-apk/app-aespaWinter-release.apk`
- `build/app/outputs/flutter-apk/app-aespaKarina-release.apk`

**App Bundle (for Play Store):**
- `build/app/outputs/bundle/kedehunRelease/app-kedehun-release.aab`
- `build/app/outputs/bundle/aespaWinterRelease/app-aespaWinter-release.aab`
- `build/app/outputs/bundle/aespaKarinaRelease/app-aespaKarina-release.aab`
