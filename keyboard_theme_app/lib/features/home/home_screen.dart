import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wallpaperengine/core/services/ad_service.dart';
import 'package:wallpaperengine/core/services/in_app_update_service.dart';
import 'package:wallpaperengine/features/detail/detail_screen.dart';
import 'package:wallpaperengine/features/favorites/favorites_screen.dart';
import 'package:wallpaperengine/config/app_config.dart';
import 'package:wallpaperengine/widgets/shimmer_grid_loading.dart';
import 'package:wallpaperengine/services/local_wallpaper_service.dart';
import 'package:wallpaperengine/services/favorites_service.dart';
import 'package:wallpaperengine/dto/wallpaper_response.dart';
import 'package:wallpaperengine/widgets/exit_dialog.dart';
import 'package:wallpaperengine/widgets/compact_exit_dialog.dart';
import 'package:wallpaperengine/widgets/minimal_exit_dialog.dart';
import 'package:wallpaperengine/models/local_wallpaper.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  final List<LocalWallpaper> _wallpapers = [];
  bool _isLoading = false;
  bool _hasMore = true;
  int _currentPage = 1;
  String? _error;
  final LocalWallpaperService _localService = LocalWallpaperService();
  final FavoritesService _favoritesService = FavoritesService();
  final InAppUpdateService _updateService = InAppUpdateService();
  int _favoritesCount = 0;
  List<String> _categories = [];
  String _selectedCategory = 'All';
  Set<String> _favoriteImages = {};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    // Clear cache to force new random shuffle on app start
    _localService.clearCache();
    _loadCategories();
    _loadWallpapers();
    _loadFavoritesCount();

    // Check for app updates after initial load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkForUpdates();
    });
  }

  Future<void> _checkForUpdates() async {
    try {
      await _updateService.checkForUpdate(context: context);
    } catch (e) {
      print('Failed to check for updates: $e');
    }
  }

  Future<void> _loadCategories() async {
    try {
      final appConfig = Provider.of<AppConfig>(context, listen: false);
      final flavor = appConfig.flavor;
      final categories = await _localService.getCategories(flavor);
      setState(() {
        _categories = categories;
        if (categories.isNotEmpty && !categories.contains(_selectedCategory)) {
          _selectedCategory = categories.first;
        }
      });
    } catch (e) {
      print('Failed to load categories: $e');
    }
  }
  
  Future<void> _loadFavoritesCount() async {
    final count = await _favoritesService.getFavoritesCount();
    final favorites = await _favoritesService.getFavorites();
    setState(() {
      _favoritesCount = count;
      _favoriteImages = favorites.toSet();
    });
  }

  Future<void> _toggleFavorite(String imageUrl) async {
    final isFavorite = _favoriteImages.contains(imageUrl);

    if (isFavorite) {
      await _favoritesService.removeFavorite(imageUrl);
      setState(() {
        _favoriteImages.remove(imageUrl);
        _favoritesCount--;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Removed from favorites'),
          duration: Duration(seconds: 1),
        ),
      );
    } else {
      await _favoritesService.addFavorite(imageUrl);
      setState(() {
        _favoriteImages.add(imageUrl);
        _favoritesCount++;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added to favorites'),
          duration: Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >= 
        _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoading && _hasMore) {
        _loadMoreWallpapers();
      }
    }
  }

  Future<void> _loadWallpapers() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final appConfig = Provider.of<AppConfig>(context, listen: false);
      final flavor = appConfig.flavor;
      print('Loading wallpapers for flavor: $flavor, category: $_selectedCategory');
      final response = await _localService.getWallpapersPaginated(
        flavor,
        1,
        15,
        category: _selectedCategory,
      );
      print('Loaded ${response.images.length} wallpapers');

      setState(() {
        _wallpapers.clear();
        _wallpapers.addAll(response.wallpapers);
        _currentPage = 1;
        _hasMore = response.hasNext;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreWallpapers() async {
    if (_isLoading || !_hasMore) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      final appConfig = Provider.of<AppConfig>(context, listen: false);
      final flavor = appConfig.flavor;
      final response = await _localService.getWallpapersPaginated(
        flavor,
        _currentPage + 1,
        15,
        category: _selectedCategory,
      );

      setState(() {
        _wallpapers.addAll(response.wallpapers);
        _currentPage++;
        _hasMore = response.hasNext;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load more wallpapers'),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: _loadMoreWallpapers,
          ),
        ),
      );
    }
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Failed to load wallpapers',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          SizedBox(height: 8),
          Text(
            _error ?? 'Unknown error',
            style: TextStyle(fontSize: 14, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadWallpapers,
            child: Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildWallpaperGrid() {
    final adService = Provider.of<AdService>(context, listen: false);

    // Calculate total items including ads
    // For every 5 thumbnails, we add 1 native ad
    final int adsCount = (_wallpapers.length / 5).floor();
    final int totalItems = _wallpapers.length + adsCount + (_hasMore ? 2 : 0);

    return MasonryGridView.count(
      controller: _scrollController,
      crossAxisCount: 1,
      mainAxisSpacing: 16,
      crossAxisSpacing: 0,
      itemCount: totalItems,
      itemBuilder: (context, index) {
        final int adsBefore = (index / 6).floor();
        final int adjustedIndex = index - adsBefore;

        final bool isAdPosition = (index + 1) % 6 == 0 && adsBefore < adsCount;

        if (isAdPosition) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: adService.createNativeAdWidget(height: 180),
          );
        }

        if (adjustedIndex >= _wallpapers.length) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  height: 190,
                  color: Colors.white,
                ),
              ),
            ),
          );
        }

        final wallpaper = _wallpapers[adjustedIndex];
        final imageUrl = wallpaper.imagePath;
        final themeAssetPath = wallpaper.themeAssetPath;
        final isSquare = wallpaper.isSquare;

        final double aspectRatio = isSquare ? 1.2 : 16 / 9;

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DetailScreen(
                  imageUrl: imageUrl,
                  themeAssetPath: themeAssetPath,
                ),
              ),
            );
          },
          child: Card(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            elevation: 3,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: AspectRatio(
              aspectRatio: aspectRatio,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.asset(
                      imageUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.35),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.keyboard, color: Colors.white, size: 14),
                          SizedBox(width: 6),
                          Text(
                            'Keyboard Theme',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: _buildThemeInfoChip(),
                  ),
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: InkWell(
                      onTap: () => _toggleFavorite(imageUrl),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.45),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          _favoriteImages.contains(imageUrl)
                              ? Icons.favorite
                              : Icons.favorite_border,
                          color: _favoriteImages.contains(imageUrl)
                              ? Colors.redAccent
                              : Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildThemeInfoChip() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.style_outlined, color: Colors.white, size: 14),
          SizedBox(width: 6),
          Text(
            'Theme Ready',
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  Future<bool> _onWillPop() async {
    final bool? result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        // You can choose between different dialog styles:
        return const MinimalExitDialog(); // Recommended: Clean with bottom banner
        // return const CompactExitDialog(); // Alternative: Compact with top banner
        // return const ExitDialog(); // Original: Large with top banner
      },
    );
    return result ?? false;
  }

  Widget build(BuildContext context) {
    final adService = Provider.of<AdService>(context);

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
      appBar: AppBar(
        centerTitle: true,
        leading: _isLoading && _wallpapers.isNotEmpty
            ? Padding(
                padding: const EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            : null,
        title: Builder(
          builder: (context) {
            final config = Provider.of<AppConfig>(context, listen: false);
            final brightness = Theme.of(context).brightness;
            return Image.asset(
              config.getLogoPath(brightness),
              height: 56,
              fit: BoxFit.contain,
              cacheHeight: 112, // 2x height for good quality
            );
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.favorite, color: Colors.red),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FavoritesScreen(),
                ),
              ).then((_) => _loadFavoritesCount()); // Refresh count when coming back
            },
            tooltip: 'Favorites',
          ),
        ],
      ),
      body: Column(
        children: [
          // Top Banner Ad
          Container(
            padding: const EdgeInsets.all(8.0),
            child: adService.createBannerAdWidget(),
          ),
          // Category Chips
          if (_categories.isNotEmpty)
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = category == _selectedCategory;
                  final isDark = Theme.of(context).brightness == Brightness.dark;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      label: Text(
                        category,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : (isDark ? Colors.white : Colors.black87),
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected && category != _selectedCategory) {
                          setState(() {
                            _selectedCategory = category;
                          });
                          _localService.reshuffleWallpapers();
                          _loadWallpapers();
                          // Scroll to top when category changes
                          if (_scrollController.hasClients) {
                            _scrollController.animateTo(
                              0,
                              duration: Duration(milliseconds: 300),
                              curve: Curves.easeOut,
                            );
                          }
                        }
                      },
                      selectedColor: Theme.of(context).primaryColor,
                      checkmarkColor: Colors.white,
                      backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected
                              ? Theme.of(context).primaryColor
                              : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
                          width: 1,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          // Content
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                _localService.reshuffleWallpapers();
                await _loadWallpapers();
              },
              child: _error != null && _wallpapers.isEmpty
                  ? _buildErrorWidget()
                  : _wallpapers.isEmpty && _isLoading
                      ? const ShimmerGridLoading(itemCount: 10)
                      : _buildWallpaperGrid(),
            ),
          ),
          // Bottom Banner Ad
          Container(
            padding: const EdgeInsets.all(8.0),
            child: adService.createBannerAdWidget(),
          ),
        ],
      ),
      ),
    );
  }
}
