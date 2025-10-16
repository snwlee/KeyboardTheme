# Kedehun Brand Assets

This directory contains brand-specific assets for the **Kedehun** (K-POP DEMON HUNTERS) flavor.

## Files to Add

Place the following files in this directory:

### Logos (Required)
- `logo_black.png` - Logo for light mode (black text/design on transparent)
  - Used in: Light theme UI
  - Recommended size: 512x512 or larger
  - Format: PNG with transparency

- `logo_white.png` - Logo for dark mode (white text/design on transparent)
  - Used in: Dark theme UI
  - Recommended size: 512x512 or larger
  - Format: PNG with transparency

### Additional Brand Assets (Optional)
- `banner.png` - Brand banner image
- `icon.png` - Small brand icon
- `background.png` - Brand-specific background

## Usage in Code

Access these assets in your Flutter code using:

```dart
// Manual approach
Image.asset('assets/kedehun/logo_black.png')
Image.asset('assets/kedehun/logo_white.png')
```

Or through AppConfig (recommended - automatically selects based on theme):

```dart
final config = Provider.of<AppConfig>(context, listen: false);
final brightness = Theme.of(context).brightness;

// Get the appropriate logo for current theme
Image.asset(config.getLogoPath(brightness))
```

## Notes

- Keep file sizes reasonable (optimize PNGs)
- Use consistent naming across all flavor directories
- These assets are flavor-specific and won't be included in other builds
