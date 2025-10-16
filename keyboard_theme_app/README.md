# Keyboard Theme App

Flutter keyboard theme application scaffolded with Android product flavors so each brand ships with its own package name, launcher icon, localized name, AdMob IDs, and asset bundle.

## Flavors

| Flavor      | Application Id                                                                 | App Name               | Asset Root            |
| ----------- | ------------------------------------------------------------------------------- | ---------------------- | --------------------- |
| `kpopdemon` | `keyboard.keyboardtheme.free.theme.custom.personalkeyboard.kpopdemon`           | KPOP Demon Keyboard    | `assets/kpopdemon/`   |
| `blackpink` | `keyboard.keyboardtheme.free.theme.custom.personalkeyboard.blackpink`           | BLACKPINK Keyboard     | `assets/blackpink/`   |

Every flavor has its own launcher icon (`android/app/src/<flavor>/res/...`) and configuration file at `android/app/src/<flavor>/res/raw/config.json`. Update the JSON to change package name, display name, asset root, keyboard locales, or AdMob identifiers for that flavor. The build script reads these values to set Gradle properties, and the Flutter layer loads the same JSON via a platform channel at runtime.

## Keyboard Themes

Keyboard themes are also declared in the flavor JSON under the `keyboardThemes` array. Each entry controls how the Flutter UI renders the preview keyboard (colors, optional background image, description, etc.). Example snippet:

```json
"keyboardThemes": [
  {
    "id": "pink-venom",
    "name": "Pink Venom",
    "description": "Sleek black glass keys with neon pink venom accents.",
    "backgroundColor": "#12000A",
    "keyColor": "#311524",
    "secondaryKeyColor": "#4D2036",
    "accentColor": "#FF4FA3",
    "keyTextColor": "#FFFFFF",
    "backgroundImage": "background_glow.png"
  }
]
```

`backgroundImage` is resolved relative to the flavor’s `assetPrefix`, so the example above loads `assets/blackpink/background_glow.png`. Add new PNG/graphics per flavor as needed; the preview automatically updates to reflect the configuration.

The home screen renders each theme as a card the user can scroll through. Tapping a card pushes a detail page with an expanded preview, color breakdown, supported keyboard locales, and an “Apply theme” action placeholder.
## Localization

The app ships with English and Korean ARB files under `lib/l10n/`. Add new locales by creating another `app_<languageCode>.arb` and re-running the localization tool:

```bash
flutter gen-l10n
```

During development the interface language can be changed from the home screen for quick verification.

## Building & Running

Install dependencies first:

```bash
flutter pub get
```

Run a specific flavor (example: `kpopdemon`) for Android:

```bash
flutter run --flavor kpopdemon --dart-define=FLAVOR=kpopdemon
```

For release builds:

```bash
flutter build apk --flavor blackpink --dart-define=FLAVOR=blackpink
```

If you omit the `--dart-define`, Android will still load the correct configuration from the flavor JSON. The define is recommended so non-Android tooling (tests, web stubs) can decide which flavor to simulate.

## Assets

Place flavor-specific keyboard graphics under the paths declared in the table above. Shared assets can live in `assets/common/` and be loaded by whichever flavor needs them.

## AdMob

The Android manifest pulls the AdMob App ID from the flavor-specific JSON via Gradle `manifestPlaceholders`. Flutter widgets read the per-flavor AdMob unit IDs from the same JSON (surfaced through `FlavorConfig`). Default configs ship with the official Google Mobile Ads sample IDs (`ca-app-pub-3940256099942544/...`) so you can test without policy violations—replace them with production keys before publishing.
