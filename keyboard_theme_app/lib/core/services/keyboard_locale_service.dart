import 'package:flutter/services.dart';

class KeyboardLocaleService {
  static const MethodChannel _channel = MethodChannel('com.example.keyboard_theme_engine/theme');

  Future<List<String>> getEnabledLocales() async {
    final result = await _channel.invokeListMethod<String>('getEnabledLocales');
    return result ?? const ['en_US'];
  }

  Future<void> setEnabledLocales(List<String> locales) async {
    await _channel.invokeMethod<void>('setEnabledLocales', {
      'locales': locales,
    });
  }
}
