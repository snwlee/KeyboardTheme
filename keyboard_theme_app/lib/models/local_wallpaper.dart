class LocalWallpaper {
  final String imagePath;
  final String category;
  final bool isSquare;

  LocalWallpaper({
    required this.imagePath,
    this.category = 'All',
    this.isSquare = false,
  });
}