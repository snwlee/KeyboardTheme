import 'dart:typed_data';

import 'package:flutter/services.dart';

class KeyboardThemeService {
  static const platform = MethodChannel('com.example.keyboard_theme_engine/theme');

  Future<void> applyKeyboardTheme(
    String assetPath, {
    String mode = 'default',
  }) async {
    try {
      final ByteData themeData = await rootBundle.load(assetPath);
      final Uint8List themeBytes = themeData.buffer.asUint8List();

      await platform.invokeMethod<void>('applyKeyboardTheme', {
        'themeBytes': themeBytes,
        'assetPath': assetPath,
        'mode': mode,
      });
    } on PlatformException catch (e) {
      throw Exception('Failed to apply keyboard theme: ${e.message}');
    } catch (e) {
      throw Exception('Unexpected error while applying keyboard theme: $e');
    }
  }

  Future<String?> getCurrentKeyboardThemePath() async {
    try {
      final String? path =
          await platform.invokeMethod<String>('getCurrentKeyboardTheme');
      return path;
    } on PlatformException catch (e) {
      throw Exception('Failed to fetch current keyboard theme: ${e.message}');
    }
  }
}
