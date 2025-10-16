import 'package:flutter/services.dart';
import 'dart:typed_data';
import 'dart:io';

class WallpaperService {
  static const platform = MethodChannel('com.example.wallpaper_engine/wallpaper');

  Future<void> setWallpaper(String imagePath, int wallpaperType) async {
    try {
      print('Setting wallpaper: $imagePath, type: $wallpaperType');

      // Load image data from assets
      ByteData imageData = await rootBundle.load(imagePath);
      Uint8List imageBytes = imageData.buffer.asUint8List();

      // Call native method with image bytes
      await platform.invokeMethod('setWallpaper', {
        'imageBytes': imageBytes,
        'wallpaperType': wallpaperType,
      });
      // Android 12+ Material You theme stabilization:
      // Native code delays 300ms on Main thread (UI stabilization)
      // Add 200ms here for Flutter widget tree to settle
      // Total: 500ms (reasonable UX for wallpaper change)
      await Future.delayed(const Duration(milliseconds: 200));
      print('Wallpaper set successfully');
    } on PlatformException catch (e) {
      print("Failed to set wallpaper: '${e.message}'.");
      throw Exception('Failed to set wallpaper: ${e.message}');
    } catch (e) {
      print("Unexpected error: $e");
      throw Exception('Unexpected error occurred: $e');
    }
  }

  Future<bool> canSetWallpaper() async {
    try {
      final bool result = await platform.invokeMethod('canSetWallpaper');
      return result;
    } on PlatformException catch (e) {
      print("Failed to check wallpaper permission: '${e.message}'.");
      return false;
    }
  }
}
