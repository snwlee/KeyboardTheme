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
    return WallpaperResponse(
      wallpapers: (json['images'] as List<dynamic>?)
          ?.map((path) => LocalWallpaper(imagePath: path as String))
          .toList() ?? [],
      brand: json['brand'] ?? '',
      category: json['category'],
      totalCount: json['totalCount'] ?? 0,
      currentPage: json['currentPage'] ?? 1,
      totalPages: json['totalPages'] ?? 1,
      hasNext: json['hasNext'] ?? false,
    );
  }
}