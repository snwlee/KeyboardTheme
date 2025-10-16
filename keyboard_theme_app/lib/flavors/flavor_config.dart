import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

  static FlavorConfig? _instance;
  static const MethodChannel _channel = MethodChannel('keyboard_theme/config');

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
    if (kIsWeb) {
      throw UnsupportedError(
        'Platform-driven flavor configs are not available on web builds.',
      );
    }
    final jsonString = await _channel.invokeMethod<String>('getConfig');
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
    return FlavorConfig(
      flavorName: json['flavorName'] as String? ??
          const String.fromEnvironment('FLAVOR', defaultValue: 'main'),
      appName: json['appName'] as String? ?? 'Keyboard Theme',
      packageName: json['packageName'] as String? ??
          'keyboard.keyboardtheme.free.theme.custom.personalkeyboard',
      assetPrefix: json['assetPrefix'] as String? ?? 'assets/common',
      admobAppId: admob['appId'] as String? ?? '',
      admobBannerId: admob['bannerId'] as String? ?? '',
      admobInterstitialId: admob['interstitialId'] as String? ?? '',
      primaryColor: _parseColor(json['primaryColor'] as String? ?? '#512DA8'),
      keyboardLocales: localesRaw
          .whereType<String>()
          .map(_parseLocale)
          .toList(growable: false),
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

  static Locale _parseLocale(String value) {
    final normalized = value.replaceAll('_', '-');
    final parts = normalized.split('-');
    if (parts.length == 1) {
      return Locale(parts.first);
    }
    return Locale(parts.first, parts[1]);
  }
}
