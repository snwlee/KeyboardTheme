import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wallpaperengine/core/services/review_service.dart';

class DownloadService {
  static final ReviewService _reviewService = ReviewService();
  static Future<bool> downloadWallpaper(String assetPath, BuildContext context) async {
    try {
      // Request storage permission based on Android version
      bool hasPermission = false;
      
      if (Platform.isAndroid) {
        if (await Permission.storage.isGranted) {
          hasPermission = true;
        } else if (await Permission.photos.isGranted) {
          hasPermission = true;
        } else {
          // Try to request the appropriate permission
          final storageStatus = await Permission.storage.request();
          final photosStatus = await Permission.photos.request();
          
          hasPermission = storageStatus.isGranted || photosStatus.isGranted;
        }
        
        if (!hasPermission) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.error, color: Colors.white),
                  SizedBox(width: 12),
                  Expanded(child: Text('Storage permission required')),
                ],
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              margin: EdgeInsets.all(16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              action: SnackBarAction(
                label: 'Settings',
                textColor: Colors.white,
                onPressed: () => openAppSettings(),
              ),
            ),
          );
          return false;
        }
      }

      // Show loading snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 12),
              Text('Downloading wallpaper...'),
            ],
          ),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

      // Load asset data
      final ByteData assetData = await rootBundle.load(assetPath);
      final Uint8List bytes = assetData.buffer.asUint8List();

      // Get download directory
      Directory? directory;
      if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory();
        // Try to use Downloads folder
        final downloadsPath = '/storage/emulated/0/Download';
        final downloadsDir = Directory(downloadsPath);
        if (await downloadsDir.exists()) {
          directory = downloadsDir;
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        throw Exception('Storage not available');
      }

      // Generate filename from asset path
      final originalFileName = assetPath.split('/').last;
      final fileExtension = originalFileName.split('.').last;
      final fileName = 'wallpaper_${DateTime.now().millisecondsSinceEpoch}.$fileExtension';
      final filePath = '${directory.path}/$fileName';

      // Write file
      final file = File(filePath);
      await file.writeAsBytes(bytes);

      // Hide loading snackbar
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      // 다운로드 성공 시 카운트 증가 및 리뷰 요청 체크
      await _reviewService.incrementDownloadCount();

      return true;
    } catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('Download failed: ${e.toString()}')),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return false;
    }
  }
}