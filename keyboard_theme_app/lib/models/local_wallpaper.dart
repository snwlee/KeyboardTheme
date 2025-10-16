class LocalWallpaper {
  /// Preview image shown in the gallery (already composited with keyboard, etc.)
  final String imagePath;

  /// Raw background asset applied to the keyboard theme inside the IME.
  final String themeAssetPath;
  final String category;
  final bool isSquare;

  LocalWallpaper({
    required this.imagePath,
    required this.themeAssetPath,
    this.category = 'All',
    this.isSquare = false,
  });
}
