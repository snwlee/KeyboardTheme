import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/keyboard_theme.dart';

/// Configuration container for per-flavor settings loaded from the native
/// platform (Android raw/config.json).
class FlavorConfig {
  const FlavorConfig({
    required this.flavorName,
    required this.appName,
    required this.packageName,
    required this.assetPrefix,
    required this.admobAppId,
    required this.admobBannerId,
    required this.admobInterstitialId,
    required this.primaryColor,
    required this.keyboardLocales,
    required this.keyboardThemes,
  });

  final String flavorName;
  final String appName;
  final String packageName;
  final String assetPrefix;
  final String admobAppId;
  final String admobBannerId;
  final String admobInterstitialId;
  final Color primaryColor;
  final List<Locale> keyboardLocales;
  final List<KeyboardThemeData> keyboardThemes;

  static FlavorConfig? _instance;
  static const String _channelName = 'keyboard_theme/config';

  static FlavorConfig get instance {
    final config = _instance;
    if (config == null) {
      throw StateError(
        'FlavorConfig has not been initialized. Call FlavorConfig.load first.',
      );
    }
    return config;
  }

  static void load(FlavorConfig config) {
    _instance = config;
  }

  /// Attempts to load the flavor configuration from the native platform.
  /// Throws if the platform is unavailable.
  static Future<FlavorConfig> fromPlatform() async {
    WidgetsFlutterBinding.ensureInitialized();
    if (kIsWeb) {
      throw UnsupportedError(
        'Platform-driven flavor configs are not available on web builds.',
      );
    }
    const channel = MethodChannel(_channelName);
    final jsonString = await channel.invokeMethod<String>('getConfig');
    if (jsonString == null || jsonString.isEmpty) {
      throw const FormatException('Received empty config payload.');
    }
    final Map<String, dynamic> data =
        json.decode(jsonString) as Map<String, dynamic>;
    return FlavorConfig.fromJson(data);
  }

  factory FlavorConfig.fromJson(Map<String, dynamic> json) {
    final admob = json['admob'] as Map<String, dynamic>? ?? const {};
    final List<dynamic> localesRaw = json['keyboardLocales'] as List<dynamic>? ?? const [];
    final assetPrefix = json['assetPrefix'] as String? ?? 'assets/common';
    final List<dynamic> themesRaw = json['keyboardThemes'] as List<dynamic>? ?? const [];
    final themes = themesRaw
        .whereType<Map<String, dynamic>>()
        .map(
          (themeJson) => _parseKeyboardTheme(
            themeJson,
            assetPrefix: assetPrefix,
          ),
        )
        .toList();

    return FlavorConfig(
      flavorName: json['flavorName'] as String? ??
          const String.fromEnvironment('FLAVOR', defaultValue: 'main'),
      appName: json['appName'] as String? ?? 'Keyboard Theme',
      packageName: json['packageName'] as String? ??
          'keyboard.keyboardtheme.free.theme.custom.personalkeyboard',
      assetPrefix: assetPrefix,
      admobAppId: admob['appId'] as String? ?? '',
      admobBannerId: admob['bannerId'] as String? ?? '',
      admobInterstitialId: admob['interstitialId'] as String? ?? '',
      primaryColor: _parseColor(json['primaryColor'] as String? ?? '#512DA8'),
      keyboardLocales: localesRaw
          .whereType<String>()
          .map(_parseLocale)
          .toList(growable: false),
      keyboardThemes: themes.isNotEmpty
          ? themes
          : [
              KeyboardThemeData(
                id: 'default',
                name: 'Default',
                description:
                    'Fallback theme generated from the flavor primary color.',
                backgroundColor: _parseColor(json['primaryColor'] as String? ?? '#512DA8'),
                keyColor: _parseColor(json['primaryColor'] as String? ?? '#512DA8')
                    .withOpacity(0.75),
                secondaryKeyColor:
                    _parseColor(json['primaryColor'] as String? ?? '#512DA8')
                        .withOpacity(0.9),
                accentColor: Colors.white,
                keyTextColor: Colors.white,
                backgroundImageAsset: null,
              ),
            ],
    );
  }

  static Color _parseColor(String value) {
    final buffer = StringBuffer();
    if (value.startsWith('#')) value = value.substring(1);
    if (value.length == 6) buffer.write('FF');
    buffer.write(value);
    final intColor = int.tryParse(buffer.toString(), radix: 16);
    if (intColor == null) {
      return const Color(0xFF512DA8);
    }
    return Color(intColor);
  }

  static KeyboardThemeData _parseKeyboardTheme(
    Map<String, dynamic> json, {
    required String assetPrefix,
  }) {
    final backgroundImage = json['backgroundImage'] as String?;
    return KeyboardThemeData(
      id: json['id'] as String? ?? 'theme-${DateTime.now().millisecondsSinceEpoch}',
      name: json['name'] as String? ?? 'Theme',
      description: json['description'] as String?,
      backgroundColor: _parseColor(json['backgroundColor'] as String? ?? '#000000'),
      keyColor: _parseColor(json['keyColor'] as String? ?? '#1F1F1F'),
      secondaryKeyColor:
          _parseColor(json['secondaryKeyColor'] as String? ?? '#2E2E2E'),
      accentColor: _parseColor(json['accentColor'] as String? ?? '#FF4081'),
      keyTextColor: _parseColor(json['keyTextColor'] as String? ?? '#FFFFFF'),
      backgroundImageAsset: backgroundImage != null
          ? '$assetPrefix/$backgroundImage'
          : null,
    );
  }

  static Locale _parseLocale(String value) {
    final normalized = value.replaceAll('_', '-');
    final parts = normalized.split('-');
    if (parts.length == 1) {
      return Locale(parts.first);
    }
    return Locale(parts.first, parts[1]);
  }
}
