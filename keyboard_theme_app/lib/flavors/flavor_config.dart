import 'package:flutter/material.dart';

/// Configuration container for per-flavor settings so the Dart layer can
/// access flavor-specific data such as assets and AdMob identifiers.
class FlavorConfig {
  const FlavorConfig({
    required this.flavorName,
    required this.appTitle,
    required this.packageName,
    required this.assetPrefix,
    required this.admobAppId,
    required this.admobBannerId,
    required this.admobInterstitialId,
    required this.primaryColor,
    required this.keyboardLocales,
  });

  final String flavorName;
  final String appTitle;
  final String packageName;
  final String assetPrefix;
  final String admobAppId;
  final String admobBannerId;
  final String admobInterstitialId;
  final Color primaryColor;
  final List<Locale> keyboardLocales;

  static FlavorConfig? _instance;

  static FlavorConfig get instance {
    final config = _instance;
    if (config == null) {
      throw StateError('FlavorConfig has not been initialized. '
          'Call FlavorConfig.load before accessing instance.');
    }
    return config;
  }

  static void load(FlavorConfig config) {
    _instance = config;
  }

  static FlavorConfig resolve(String name) {
    return presets[name] ?? presets['kpopdemon']!;
  }

  static final Map<String, FlavorConfig> presets = {
    'kpopdemon': FlavorConfig(
      flavorName: 'kpopdemon',
      appTitle: 'KPOP Demon Keyboard',
      packageName:
          'keyboard.keyboardtheme.free.theme.custom.personalkeyboard.kpopdemon',
      assetPrefix: 'assets/kpopdemon',
      admobAppId: 'ca-app-pub-xxxxxxxxxxxxxxxx~kpopdemon',
      admobBannerId: 'ca-app-pub-xxxxxxxxxxxxxxxx/kpopdemonBanner',
      admobInterstitialId:
          'ca-app-pub-xxxxxxxxxxxxxxxx/kpopdemonInterstitial',
      primaryColor: const Color(0xFF311B92),
      keyboardLocales: const [
        Locale('ko'),
        Locale('en'),
        Locale('ja'),
      ],
    ),
    'blackpink': FlavorConfig(
      flavorName: 'blackpink',
      appTitle: 'BLACKPINK Keyboard',
      packageName:
          'keyboard.keyboardtheme.free.theme.custom.personalkeyboard.blackpink',
      assetPrefix: 'assets/blackpink',
      admobAppId: 'ca-app-pub-xxxxxxxxxxxxxxxx~blackpink',
      admobBannerId: 'ca-app-pub-xxxxxxxxxxxxxxxx/blackpinkBanner',
      admobInterstitialId:
          'ca-app-pub-xxxxxxxxxxxxxxxx/blackpinkInterstitial',
      primaryColor: const Color(0xFF880E4F),
      keyboardLocales: const [
        Locale('ko'),
        Locale('en'),
        Locale('th'),
      ],
    ),
  };
}
