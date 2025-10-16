import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// AdMob configuration for each flavor
class AdMobSettings {
  final String bannerAdUnitId;
  final String interstitialAdUnitId;
  final String appOpenAdUnitId;
  final String rewardedAdUnitId;
  final String nativeAdUnitId;

  AdMobSettings({
    required this.bannerAdUnitId,
    required this.interstitialAdUnitId,
    required this.appOpenAdUnitId,
    required this.rewardedAdUnitId,
    required this.nativeAdUnitId,
  });

  factory AdMobSettings.fromJson(Map<String, dynamic> json) {
    return AdMobSettings(
      bannerAdUnitId: json['bannerAdUnitId'] ?? '',
      interstitialAdUnitId: json['interstitialAdUnitId'] ?? '',
      appOpenAdUnitId: json['appOpenAdUnitId'] ?? '',
      rewardedAdUnitId: json['rewardedAdUnitId'] ?? '',
      nativeAdUnitId: json['nativeAdUnitId'] ?? '',
    );
  }
}

class AppConfig {
  final String flavor;
  final String appName;
  final Color themeColor;
  final String apiUrl;
  final String logoLightPath;
  final String logoDarkPath;
  final AdMobSettings admobSettings;

  AppConfig._({
    required this.flavor,
    required this.appName,
    required this.themeColor,
    required this.apiUrl,
    required this.logoLightPath,
    required this.logoDarkPath,
    required this.admobSettings,
  });

  static AppConfig? _instance;

  static AppConfig get instance {
    if (_instance == null) {
      throw Exception("AppConfig not initialized. Call AppConfig.initialize() first.");
    }
    return _instance!;
  }

  /// Get logo path based on current brightness
  String getLogoPath(Brightness brightness) {
    return brightness == Brightness.dark ? logoDarkPath : logoLightPath;
  }

  static Future<void> initialize() async {
    if (_instance != null) return; // Already initialized

    try {
      const platform = MethodChannel('com.snwlee.wallpaperengine/resources');
      
      // Fetch both config.json and app_name from native in parallel
      final results = await Future.wait([
        platform.invokeMethod('getFlavorConfig'),
        platform.invokeMethod('getAppName'),
      ]);

      final String jsonString = results[0] as String;
      final String appNameFromNative = results[1] as String;
      
      final Map<String, dynamic> json = jsonDecode(jsonString);

      _instance = AppConfig._(
        flavor: json['flavor'] ?? '',
        appName: appNameFromNative, // Use appName from native
        themeColor: _colorFromHex(json['themeColor'] ?? '#FFFFFF'),
        apiUrl: json['apiUrl'] ?? '',
        logoLightPath: json['logoLightPath'] ?? '',
        logoDarkPath: json['logoDarkPath'] ?? '',
        admobSettings: AdMobSettings.fromJson(json['admobSettings'] ?? {}),
      );
      print('AppConfig initialized for flavor: ${_instance!.flavor}');
    } catch (e) {
      print('Failed to initialize AppConfig: $e');
      print('Falling back to a default configuration.');
      _instance = AppConfig._(
        flavor: 'default',
        appName: 'Wallpaper App',
        themeColor: Colors.blue,
        apiUrl: '',
        logoLightPath: '',
        logoDarkPath: '',
        admobSettings: AdMobSettings(bannerAdUnitId: '', interstitialAdUnitId: '', appOpenAdUnitId: '', rewardedAdUnitId: '', nativeAdUnitId: ''),
      );
    }
  }

  static Color _colorFromHex(String hexColor) {
    hexColor = hexColor.toUpperCase().replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF' + hexColor;
    }
    return Color(int.parse(hexColor, radix: 16));
  }
}