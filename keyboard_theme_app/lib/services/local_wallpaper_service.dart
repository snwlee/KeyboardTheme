import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import '../models/local_wallpaper.dart';
import '../dto/wallpaper_response.dart';

class LocalWallpaperService {
  static final LocalWallpaperService _instance = LocalWallpaperService._internal();
  factory LocalWallpaperService() => _instance;
  LocalWallpaperService._internal();

  List<LocalWallpaper>? _cachedWallpapers;
  List<LocalWallpaper>? _shuffledWallpapers;
  final Random _random = Random();
  String? _currentFlavor; // Track current flavor

  Future<List<LocalWallpaper>> _loadWallpapersFromAssets(String flavor) async {
    // Clear cache if flavor changed
    if (_currentFlavor != null && _currentFlavor != flavor) {
      clearCache();
    }
    _currentFlavor = flavor;

    if (_cachedWallpapers != null) {
      return _cachedWallpapers!;
    }

    final manifestContent = await rootBundle.loadString('AssetManifest.json');
    final Map<String, dynamic> manifestMap = json.decode(manifestContent);

    // Look for wallpapers in flavor-specific directory: assets/{flavor}/wallpapers/
    final flavorWallpapersPath = 'assets/$flavor/wallpapers/';
    print('Looking for wallpapers in: $flavorWallpapersPath');

    final List<String> imagePaths = manifestMap.keys
        .where((String key) => key.startsWith(flavorWallpapersPath))
        .where((String key) =>
            key.endsWith('.jpg') ||
            key.endsWith('.png') ||
            key.endsWith('.jpeg'))
        .toList();

    print('Found ${imagePaths.length} image paths from assets for flavor: $flavor');

    // Extract unique categories from folder structure
    final Set<String> categoriesFound = {};

    final List<LocalWallpaper> wallpapers = imagePaths.map((path) {
      // Extract category from path
      // Example: assets/kedehun/wallpapers/category1/image.jpg -> category1
      // Example: assets/kedehun/wallpapers/category1/profile/image.jpg -> category1 (profile)
      // Example: assets/kedehun/wallpapers/profile/image.jpg -> profile image (no category)
      final parts = path.split('/');
      String specificCategory = '';
      bool isSquare = false;

      if (parts.length > 4) {
        // Path has subdirectory: assets/{flavor}/wallpapers/[category]/image.jpg
        specificCategory = parts[3];

        // Check if it's in a profile subfolder (for square images)
        if (parts.length > 5 && parts[4] == 'profile') {
          // assets/kedehun/wallpapers/category1/profile/image.jpg
          isSquare = true;
        } else if (specificCategory == 'profile') {
          // assets/kedehun/wallpapers/profile/image.jpg - root profile folder
          isSquare = true;
          specificCategory = ''; // No category for root profile images
        } else {
          // Only add non-profile folders as categories
          categoriesFound.add(specificCategory);
        }
      }

      return LocalWallpaper(
        imagePath: path,
        category: specificCategory, // Store specific category, empty string if in root
        isSquare: isSquare,
      );
    }).toList();

    // Log found categories
    if (categoriesFound.isNotEmpty) {
      print('Found categories from folder structure: ${categoriesFound.toList()..sort()}');
    } else {
      print('No category subdirectories found, all images are in root wallpapers folder');
    }

    _cachedWallpapers = wallpapers;
    print('Created ${wallpapers.length} wallpapers total for flavor: $flavor');
    return wallpapers;
  }

  // Shuffle wallpapers randomly
  List<LocalWallpaper> _getShuffledWallpapers() {
    if (_shuffledWallpapers == null && _cachedWallpapers != null) {
      _shuffledWallpapers = List.from(_cachedWallpapers!);
      _shuffledWallpapers!.shuffle(_random);
      print('Wallpapers shuffled randomly');
    }
    return _shuffledWallpapers ?? [];
  }

  // Force reshuffle (for refresh)
  void reshuffleWallpapers() {
    if (_cachedWallpapers != null) {
      _shuffledWallpapers = List.from(_cachedWallpapers!);
      _shuffledWallpapers!.shuffle(_random);
      print('Wallpapers reshuffled');
    }
  }

  // Clear cache and force new shuffle on next load
  void clearCache() {
    _cachedWallpapers = null;
    _shuffledWallpapers = null;
    print('Wallpaper cache cleared');
  }



  // Get all available categories from actual folder structure
  Future<List<String>> getCategories(String flavor) async {
    await _loadWallpapersFromAssets(flavor);

    if (_cachedWallpapers == null || _cachedWallpapers!.isEmpty) {
      print('No wallpapers found for flavor: $flavor');
      return ['All'];
    }

    // Extract unique categories from wallpapers (excluding empty strings)
    final categoriesSet = _cachedWallpapers!
        .map((w) => w.category)
        .where((cat) => cat.isNotEmpty) // Only non-empty categories
        .toSet();

    // Always put 'All' first, then sort the rest alphabetically
    final categories = <String>['All'];
    final otherCategories = categoriesSet.toList()..sort();
    categories.addAll(otherCategories);

    print('Available categories for $flavor: $categories');
    return categories;
  }

  Future<WallpaperResponse> getWallpapersPaginated(
    String flavor,
    int page,
    int size, {
    String? category,
  }) async {
    await Future.delayed(Duration(milliseconds: 500));

    await _loadWallpapersFromAssets(flavor);
    final shuffledWallpapers = _getShuffledWallpapers();

    // Filter by category if specified
    List<LocalWallpaper> filteredWallpapers = shuffledWallpapers;
    if (category != null && category != 'All') {
      // Filter to specific category only
      filteredWallpapers = shuffledWallpapers
          .where((w) => w.category == category)
          .toList();
      print('Filtered to ${filteredWallpapers.length} wallpapers for category: $category');
    } else {
      // 'All' category shows everything
      print('Showing all ${filteredWallpapers.length} wallpapers for "All" category');
    }

    int startIndex = (page - 1) * size;
    int endIndex = startIndex + size;

    if (startIndex >= filteredWallpapers.length) {
      return WallpaperResponse(
        wallpapers: [],
        brand: flavor,
        category: category,
        totalCount: filteredWallpapers.length,
        currentPage: page,
        totalPages: (filteredWallpapers.length / size).ceil(),
        hasNext: false,
      );
    }

    endIndex = endIndex > filteredWallpapers.length
        ? filteredWallpapers.length
        : endIndex;

    List<LocalWallpaper> pageWallpapers = filteredWallpapers
        .sublist(startIndex, endIndex);

    print('Returning shuffled page $page with ${pageWallpapers.length} wallpapers, hasNext: ${endIndex < filteredWallpapers.length}');

    return WallpaperResponse(
      wallpapers: pageWallpapers,
      brand: flavor,
      category: category,
      totalCount: filteredWallpapers.length,
      currentPage: page,
      totalPages: (filteredWallpapers.length / size).ceil(),
      hasNext: endIndex < filteredWallpapers.length,
    );
  }

}