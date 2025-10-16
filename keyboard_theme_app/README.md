# Keyboard Theme App

Flutter keyboard theme application scaffolded with Android product flavors so each brand ships with its own package name, launcher icon, localized name, AdMob IDs, and asset bundle.

## Flavors

| Flavor      | Application Id                                                                 | App Name               | Asset Root            |
| ----------- | ------------------------------------------------------------------------------- | ---------------------- | --------------------- |
| `kpopdemon` | `keyboard.keyboardtheme.free.theme.custom.personalkeyboard.kpopdemon`           | KPOP Demon Keyboard    | `assets/kpopdemon/`   |
| `blackpink` | `keyboard.keyboardtheme.free.theme.custom.personalkeyboard.blackpink`           | BLACKPINK Keyboard     | `assets/blackpink/`   |

Every flavor has its own launcher icon (`android/app/src/<flavor>/res/...`) and placeholder AdMob configuration declared in `lib/flavors/flavor_config.dart`. Replace the placeholder IDs with production values before release.

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
flutter run --flavor kpopdemon -t lib/main_kpopdemon.dart
```

For release builds:

```bash
flutter build apk --flavor blackpink -t lib/main_blackpink.dart
```

If you prefer `flutter run` without specifying `-t`, pass the flavor as a Dart define:

```bash
flutter run --flavor blackpink --dart-define=FLAVOR=blackpink
```

## Assets

Place flavor-specific keyboard graphics under the paths declared in the table above. Shared assets can live in `assets/common/` and loaded by whichever flavor needs them.

## AdMob

The Android manifest pulls the AdMob App ID from the flavor-specific `manifestPlaceholders`. Flutter widgets read the per-flavor AdMob unit IDs exposed by `FlavorConfig`. Keep unique keys for each flavor to avoid revenue attribution issues.
