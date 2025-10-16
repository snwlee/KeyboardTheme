# Google Play In-App Update Integration Guide

## Overview
This app now includes Google Play In-App Update API integration, providing seamless app updates for users without leaving the app.

## Features

### 1. Flexible Update Flow
- User can download updates in the background
- App remains fully functional during download
- User-friendly dialog with Korean text
- After 3 prompts, update becomes mandatory

### 2. Immediate Update Flow
- For critical updates (priority >= 4)
- Blocks app usage until update is installed
- Automatically triggered for high-priority updates
- Mandatory update dialog if user cancels

### 3. Smart Update Checking
- Automatic check on app start (HomeScreen)
- Rate limiting: checks once every 24 hours
- Update prompt counter to prevent spam
- Proper state checks to avoid crashes

## Implementation Details

### Files Modified/Created:
1. **lib/core/services/in_app_update_service.dart** (NEW)
   - Main service handling all update logic
   - Flexible and immediate update flows
   - Update check throttling
   - User-friendly Korean dialogs

2. **lib/features/home/home_screen.dart** (MODIFIED)
   - Added update check on app start
   - Integrated InAppUpdateService

3. **pubspec.yaml** (MODIFIED)
   - Added `in_app_update: ^4.2.3` dependency

## Usage

### Basic Usage (Automatic)
The update check runs automatically when the app starts. No additional code needed.

### Manual Update Check
```dart
final updateService = InAppUpdateService();
await updateService.checkForUpdate(
  context: context,
  forceImmediate: false,  // Set true for mandatory updates
  showNoUpdateSnackbar: true,  // Show message when up to date
);
```

### Testing In-App Updates

#### Prerequisites:
1. App must be published on Google Play (Internal Testing, Closed Testing, or Production)
2. Cannot test with debug builds or local APKs
3. Need two versions: current version and higher version on Play Store

#### Testing Steps:

**1. Setup for Testing:**
```bash
# Build and upload version 1.0.0+1 to Internal Testing track
flutter build appbundle --release --flavor kedehun
# Upload to Google Play Console → Internal Testing

# Install on test device from Play Store
# Wait for app to be available (~2 hours for first release)
```

**2. Test Flexible Update:**
```bash
# Increase version to 1.0.0+2 in pubspec.yaml
# Set update priority to 1-3 in Play Console
flutter build appbundle --release --flavor kedehun
# Upload as new release to Internal Testing

# On test device with v1 installed:
# 1. Open the app
# 2. Should see flexible update dialog
# 3. Click "업데이트" to start download
# 4. App continues working during download
# 5. When complete, app will restart with new version
```

**3. Test Immediate Update:**
```bash
# Increase version to 1.0.0+3 in pubspec.yaml
# Set update priority to 4-5 in Play Console
flutter build appbundle --release --flavor kedehun
# Upload as new release to Internal Testing

# On test device with v2 installed:
# 1. Open the app
# 2. Should see immediate update flow
# 3. App blocks usage until update completes
```

**4. Test Using Internal App Sharing (Faster Testing):**
```bash
# Enable Internal App Sharing in Play Console
# Upload via Play Console → Release → Internal app sharing

# On test device:
# 1. Enable Internal app sharing in Play Store settings
# 2. Open Internal app sharing link
# 3. Install app
# 4. Repeat with higher version to test updates
```

#### Common Testing Issues:

1. **"No update available"**
   - Ensure device has older version installed from Play Store
   - Check update priority in Play Console
   - Wait 24 hours or clear app data to reset check interval

2. **Update not triggering**
   - Verify app was installed from Play Store, not sideloaded
   - Check device has Google Play Services
   - Ensure versions match (lower installed, higher on Play)

3. **Update check error**
   - Check device is connected to internet
   - Verify Play Store is up to date
   - Clear Play Store cache

## Configuration Options

### Update Priority Levels (Set in Play Console):
- **0**: No update required
- **1-3**: Flexible update (user can postpone)
- **4-5**: Immediate update (mandatory)

### Customization:
Edit `in_app_update_service.dart` to customize:
- Update check interval (default: 24 hours)
- Update prompt frequency before forcing
- Dialog text and styling
- Update priority thresholds

## Update Flow Diagram

```
App Start
    ↓
Check Last Update Time
    ↓
< 24 hours? → Skip Check
≥ 24 hours? → Continue
    ↓
Query Play Store API
    ↓
Update Available?
    ↓
Yes → Check Priority
    ↓
Priority ≥ 4? → Immediate Update
Priority < 4? → Flexible Update
    ↓
User Decision
    ↓
Accept → Download & Install
Decline → Increment Counter
    ↓
Counter ≥ 3? → Force Update
```

## Best Practices

1. **Set appropriate priority levels:**
   - Priority 5: Critical security fixes
   - Priority 4: Major bugs affecting functionality
   - Priority 1-3: Feature updates, minor fixes

2. **Test thoroughly:**
   - Always test on Internal Testing track first
   - Test both update flows
   - Test update cancellation scenarios

3. **Monitor update adoption:**
   - Use Play Console to track update percentages
   - Increase priority if adoption is slow

4. **Handle edge cases:**
   - No internet connection
   - Insufficient storage
   - Play Store not available

## Troubleshooting

### Logs
Check Android logcat for update-related logs:
```bash
adb logcat | grep -i "update\|InAppUpdate"
```

### Common Log Messages:
- `"Update available: <version>"` - Update detected
- `"Starting flexible update..."` - Flexible flow initiated
- `"Starting immediate update..."` - Immediate flow initiated
- `"User cancelled update"` - User declined update
- `"No update available"` - App is up to date

## Additional Resources
- [Google Play In-App Updates Documentation](https://developer.android.com/guide/playcore/in-app-updates)
- [in_app_update Flutter Package](https://pub.dev/packages/in_app_update)
- [Testing Internal App Sharing](https://support.google.com/googleplay/android-developer/answer/9303479)
