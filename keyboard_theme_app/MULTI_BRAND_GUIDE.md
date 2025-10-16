# Multi-Brand Flutter App Guide

This guide explains how to build and maintain multiple brands (flavors) of the wallpaper app.

## Overview

The app supports multiple brands with independent:
- App names and package IDs
- AdMob configurations
- App icons and logos
- Color themes
- Signing keys (JKS keystores)

## Available Flavors

### 1. Kedehun (Default)
- **App Name**: K-POP DEMON HUNTERS
- **Package**: `com.snwlee.wallpaperengine.kedehun`
- **Theme**: Material Blue (#2196F3)
- **Status**: Production ready

### 2. Aespa Winter
- **App Name**: Aespa Winter Wallpaper
- **Package**: `com.snwlee.wallpaperengine.aespawinter`
- **Theme**: Pink (#E91E63)
- **Status**: AdMob IDs need to be configured

### 3. Aespa Karina
- **App Name**: Aespa Karina Wallpaper
- **Package**: `com.snwlee.wallpaperengine.aespakarina`
- **Theme**: Purple (#9C27B0)
- **Status**: AdMob IDs need to be configured

## Building Flavors

### Quick Build Commands

#### Using Build Scripts (Recommended)

**Windows:**
```bash
# Build APK
scripts\build_flavor.bat kedehun apk
scripts\build_flavor.bat aespa_winter apk
scripts\build_flavor.bat aespa_karina apk

# Build App Bundle (for Play Store)
scripts\build_flavor.bat kedehun appbundle
```

**Linux/Mac:**
```bash
# Make script executable (first time only)
chmod +x scripts/build_flavor.sh

# Build APK
./scripts/build_flavor.sh kedehun apk
./scripts/build_flavor.sh aespa_winter apk
./scripts/build_flavor.sh aespa_karina apk

# Build App Bundle (for Play Store)
./scripts/build_flavor.sh kedehun appbundle
```

#### Manual Build Commands

```bash
# Kedehun
flutter build apk --release --flavor kedehun --dart-define=FLAVOR=kedehun

# Aespa Winter
flutter build apk --release --flavor aespaWinter --dart-define=FLAVOR=aespa_winter

# Aespa Karina
flutter build apk --release --flavor aespaKarina --dart-define=FLAVOR=aespa_karina
```

### Debug Builds

```bash
flutter run --flavor kedehun --dart-define=FLAVOR=kedehun
flutter run --flavor aespaWinter --dart-define=FLAVOR=aespa_winter
flutter run --flavor aespaKarina --dart-define=FLAVOR=aespa_karina
```

## Configuration Structure

### 1. Flutter Configuration

**AdMob Configuration** (`lib/config/`)
- `admob_config.dart` - Base AdMob configuration interface
- `admob_kedehun.dart` - Kedehun AdMob IDs
- `admob_aespa_winter.dart` - Aespa Winter AdMob IDs
- `admob_aespa_karina.dart` - Aespa Karina AdMob IDs

**App Configuration** (`lib/config/app_config.dart`)
- App name
- Theme colors
- API URLs
- Logo paths
- AdMob configuration

### 2. Android Configuration

**Build Configuration** (`android/app/build.gradle.kts`)
- Product flavors (kedehun, aespaWinter, aespaKarina)
- Signing configurations
- Manifest placeholders for AdMob App IDs

**Keystore Files** (`android/app/keystore/`)
```
keystore/
├── kedehun.jks           # Production keystore
├── aespa_winter.jks      # To be generated
└── aespa_karina.jks      # To be generated
```

**Keystore Properties** (`android/`)
```
key_kedehun.properties          # Production credentials
key_aespa_winter.properties     # To be created
key_aespa_karina.properties     # To be created
```

**Flavor-Specific Resources** (`android/app/src/`)
```
src/
├── kedehun/res/          # Kedehun icons
├── aespaWinter/res/      # Winter icons
├── aespaKarina/res/      # Karina icons
└── main/res/             # Shared resources
```

### 3. Assets

**Flutter Assets** (`assets/`)
```
assets/
├── kedehun/
│   └── logo.png
├── aespa_winter/
│   └── logo.png
└── aespa_karina/
    └── logo.png
```

## Adding a New Flavor

### Step 1: Create AdMob Configuration

1. Create `lib/config/admob_your_flavor.dart`:
```dart
import 'admob_config.dart';

class AdMobYourFlavor extends AdMobConfig {
  @override
  String get interstitialAdUnitId => 'ca-app-pub-xxxxx';

  @override
  String get splashInterstitialAdUnitId => 'ca-app-pub-xxxxx';

  @override
  String get bannerAdUnitId => 'ca-app-pub-xxxxx';

  @override
  String get appOpenAdUnitId => 'ca-app-pub-xxxxx';

  @override
  String get rewardedAdUnitId => 'ca-app-pub-xxxxx';

  @override
  String get admobAppId => 'ca-app-pub-xxxxx';
}
```

2. Update `lib/config/app_config.dart` to add your flavor case

### Step 2: Add Android Flavor

1. Edit `android/app/build.gradle.kts`:
```kotlin
create("yourFlavor") {
    dimension = "app"
    applicationIdSuffix = ".yourflavor"
    resValue("string", "app_name", "Your Flavor Name")
    manifestPlaceholders["admobAppId"] = "ca-app-pub-xxxxx"
}
```

2. Add signing config:
```kotlin
create("yourFlavorRelease") {
    val props = loadKeystoreProperties("your_flavor")
    keyAlias = props["keyAlias"] as? String
    keyPassword = props["keyPassword"] as? String
    storeFile = props["storeFile"]?.let { file(it.toString()) }
    storePassword = props["storePassword"] as? String
}
```

### Step 3: Generate Keystore

```bash
keytool -genkey -v -keystore android/app/keystore/your_flavor.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Create `android/key_your_flavor.properties`:
```properties
storePassword=YOUR_PASSWORD
keyPassword=YOUR_PASSWORD
keyAlias=upload
storeFile=keystore/your_flavor.jks
```

### Step 4: Add Assets and Icons

1. Create directories:
   - `assets/your_flavor/`
   - `android/app/src/yourFlavor/res/`

2. Add app icons to res directory
3. Add logo.png to assets directory

### Step 5: Update pubspec.yaml

Add to assets list:
```yaml
assets:
  - assets/your_flavor/
```

## Security Best Practices

### Keystore Management

- **NEVER commit** `.jks` files or properties files with real credentials to git
- Keep keystores in a secure backup location
- Use different passwords for each flavor
- Store passwords in a password manager

### AdMob IDs

- Use test IDs during development
- Replace with production IDs before release
- Keep AdMob credentials secure

### Git Ignore

Ensure these are in `.gitignore`:
```
android/key_*.properties
!android/key_*.properties.example
android/app/keystore/*.jks
```

## Troubleshooting

### Build Errors

**Problem**: `Execution failed for task ':app:packageKedehunRelease'`
**Solution**: Check that keystore file exists and properties file is correct

**Problem**: AdMob ads not showing
**Solution**:
1. Verify AdMob App ID in build.gradle.kts
2. Check Ad Unit IDs in config files
3. Ensure test device is registered for test ads

**Problem**: Flavor-specific resources not loading
**Solution**:
1. Clean and rebuild: `flutter clean && flutter pub get`
2. Verify resource directory structure
3. Check that flavor name matches exactly (case-sensitive)

### Common Issues

1. **Signing config not found**
   - Ensure `key_<flavor>.properties` file exists
   - Check file path in properties file

2. **Wrong app name displayed**
   - Verify `resValue("string", "app_name", ...)` in build.gradle.kts
   - Check AndroidManifest.xml uses `@string/app_name`

3. **Assets not found at runtime**
   - Verify assets are listed in pubspec.yaml
   - Rebuild app after adding assets

## Publishing to Play Store

### Checklist for Each Flavor

- [ ] Generate production keystore
- [ ] Configure production AdMob IDs
- [ ] Add app icons (all densities)
- [ ] Add app logo to assets
- [ ] Test build with `--release` flag
- [ ] Update version in pubspec.yaml
- [ ] Build app bundle: `flutter build appbundle --flavor <flavor>`
- [ ] Upload to Play Console
- [ ] Configure store listing (unique for each flavor)

### App Bundle Location

After building:
```
build/app/outputs/bundle/
├── kedehunRelease/app-kedehun-release.aab
├── aespaWinterRelease/app-aespaWinter-release.aab
└── aespaKarinaRelease/app-aespaKarina-release.aab
```

## Support

For questions or issues:
1. Check this guide first
2. Review flavor-specific README files in asset directories
3. Check Android resource README files
4. Review keystore README in `android/app/keystore/`
