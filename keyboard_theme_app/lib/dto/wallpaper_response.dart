import '../models/local_wallpaper.dart';

class WallpaperResponse {
  final List<LocalWallpaper> wallpapers;
  final String brand;
  final String? category;
  final int totalCount;
  final int currentPage;
  final int totalPages;
  final bool hasNext;

  WallpaperResponse({
    required this.wallpapers,
    required this.brand,
    this.category,
    required this.totalCount,
    required this.currentPage,
    required this.totalPages,
    required this.hasNext,
  });

  // Backwards compatibility: return image paths
  List<String> get images => wallpapers.map((w) => w.imagePath).toList();

  factory WallpaperResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> imageList = json['images'] as List<dynamic>? ?? [];
    final List<dynamic>? themeList = json['themes'] as List<dynamic>?;

    final wallpapers = <LocalWallpaper>[];
    for (int i = 0; i < imageList.length; i++) {
      final preview = imageList[i] as String;
      String? theme;
      if (themeList != null && themeList.length > i) {
        theme = themeList[i] as String?;
      }
      theme ??= preview.replaceFirst('/wallpapers/', '/keyboard_themes/');
      wallpapers.add(
        LocalWallpaper(
          imagePath: preview,
          themeAssetPath: theme ?? preview,
        ),
      );
    }

    return WallpaperResponse(
      wallpapers: wallpapers,
      brand: json['brand'] ?? '',
      category: json['category'],
      totalCount: json['totalCount'] ?? 0,
      currentPage: json['currentPage'] ?? 1,
      totalPages: json['totalPages'] ?? 1,
      hasNext: json['hasNext'] ?? false,
    );
  }
}
