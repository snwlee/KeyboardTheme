# Keyboard Theme App

Flutter keyboard theme application scaffolded with Android product flavors so each brand ships with its own package name, launcher icon, localized name, AdMob IDs, and asset bundle.

## Flavors

| Flavor      | Application Id                                                                 | App Name               | Asset Root            |
| ----------- | ------------------------------------------------------------------------------- | ---------------------- | --------------------- |
| `kpopdemon` | `keyboard.keyboardtheme.free.theme.custom.personalkeyboard.kpopdemon`           | KPOP Demon Keyboard    | `assets/kpopdemon/`   |
| `blackpink` | `keyboard.keyboardtheme.free.theme.custom.personalkeyboard.blackpink`           | BLACKPINK Keyboard     | `assets/blackpink/`   |

Every flavor has its own launcher icon (`android/app/src/<flavor>/res/...`) and configuration file at `android/app/src/<flavor>/res/raw/config.json`. Update the JSON to change package name, display name, asset root, keyboard locales, or AdMob identifiers for that flavor. The build script reads these values to set Gradle properties, and the Flutter layer loads the same JSON via a platform channel at runtime.

All flavors share a single `lib/main.dart`; you only need to add a new `config.json` (and optional fallback entry in `FlavorConfig`) when introducing additional brands.
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

If you omit the `--dart-define`, Android will still load the correct configuration from the flavor JSON. The define is recommended so fallback builds (e.g., web, tests) also resolve the right flavor.

```bash
flutter run --flavor blackpink --dart-define=FLAVOR=blackpink
```

## Assets

Place flavor-specific keyboard graphics under the paths declared in the table above. Shared assets can live in `assets/common/` and be loaded by whichever flavor needs them.

## AdMob

The Android manifest pulls the AdMob App ID from the flavor-specific JSON via Gradle `manifestPlaceholders`. Flutter widgets read the per-flavor AdMob unit IDs from the same JSON (surfaced through `FlavorConfig`). Keep unique keys for each flavor to avoid revenue attribution issues.
