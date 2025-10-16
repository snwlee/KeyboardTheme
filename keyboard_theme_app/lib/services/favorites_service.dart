import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class FavoritesService {
  static const String _favoritesKey = 'favorites_list';
  
  static final FavoritesService _instance = FavoritesService._internal();
  factory FavoritesService() => _instance;
  FavoritesService._internal();

  final List<String> _favorites = [];
  bool _isLoaded = false;

  // Load favorites from SharedPreferences
  Future<void> _loadFavorites() async {
    if (_isLoaded) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoritesJson = prefs.getStringList(_favoritesKey) ?? [];
      _favorites.clear();
      _favorites.addAll(favoritesJson);
      _isLoaded = true;
    } catch (e) {
      print('Error loading favorites: $e');
    }
  }

  // Save favorites to SharedPreferences
  Future<void> _saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(_favoritesKey, _favorites);
    } catch (e) {
      print('Error saving favorites: $e');
    }
  }

  // Add to favorites
  Future<void> addFavorite(String imagePath) async {
    await _loadFavorites();
    if (!_favorites.contains(imagePath)) {
      _favorites.add(imagePath);
      await _saveFavorites();
    }
  }

  // Remove from favorites
  Future<void> removeFavorite(String imagePath) async {
    await _loadFavorites();
    _favorites.remove(imagePath);
    await _saveFavorites();
  }

  // Check if image is favorite
  Future<bool> isFavorite(String imagePath) async {
    await _loadFavorites();
    return _favorites.contains(imagePath);
  }

  // Get all favorites
  Future<List<String>> getFavorites() async {
    await _loadFavorites();
    return List.from(_favorites);
  }

  // Toggle favorite status
  Future<bool> toggleFavorite(String imagePath) async {
    await _loadFavorites();
    final isFav = _favorites.contains(imagePath);
    if (isFav) {
      await removeFavorite(imagePath);
      return false;
    } else {
      await addFavorite(imagePath);
      return true;
    }
  }

  // Get favorites count
  Future<int> getFavoritesCount() async {
    await _loadFavorites();
    return _favorites.length;
  }
}