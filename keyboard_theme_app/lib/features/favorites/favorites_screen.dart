import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wallpaperengine/services/favorites_service.dart';
import 'package:wallpaperengine/features/detail/detail_screen.dart';
import 'package:wallpaperengine/core/services/ad_service.dart';

class FavoritesScreen extends StatefulWidget {
  @override
  _FavoritesScreenState createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> with TickerProviderStateMixin {
  final FavoritesService _favoritesService = FavoritesService();
  List<String> _favorites = [];
  bool _isLoading = true;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
    _loadFavorites();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    setState(() {
      _isLoading = true;
    });

    final favorites = await _favoritesService.getFavorites();
    setState(() {
      _favorites = favorites;
      _isLoading = false;
    });

    _animationController.forward();
  }

  Future<void> _removeFavorite(String imagePath) async {
    await _favoritesService.removeFavorite(imagePath);
    await _loadFavorites();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.heart_broken, color: Colors.white),
            SizedBox(width: 12),
            Text('Removed from favorites'),
          ],
        ),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        action: SnackBarAction(
          label: 'Undo',
          textColor: Colors.white,
          onPressed: () async {
            await _favoritesService.addFavorite(imagePath);
            await _loadFavorites();
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(60),
            ),
            child: Icon(
              Icons.favorite_border,
              size: 60,
              color: Colors.grey[400],
            ),
          ),
          SizedBox(height: 24),
          Text(
            'No Favorites Yet',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Tap the heart icon on any wallpaper\nto add it to your favorites',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoritesList() {
    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: 8),
      itemCount: _favorites.length,
      itemBuilder: (context, index) {
        final imagePath = _favorites[index];
        final isSquare = _isSquarePreview(imagePath);
        final aspectRatio = isSquare ? 1.2 : 16 / 9;

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) => DetailScreen(
                  imageUrl: imagePath,
                  themeAssetPath: _deriveThemeAssetPath(imagePath),
                ),
                transitionDuration: Duration(milliseconds: 300),
                transitionsBuilder: (context, animation, secondaryAnimation, child) {
                  return FadeTransition(opacity: animation, child: child);
                },
              ),
            ).then((_) => _loadFavorites());
          },
          onLongPress: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: Text('Remove from Favorites?'),
                content: Text('This wallpaper will be removed from your favorites.'),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Cancel'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _removeFavorite(imagePath);
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    child: Text('Remove'),
                  ),
                ],
              ),
            );
          },
          child: Card(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            clipBehavior: Clip.antiAlias,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            child: AspectRatio(
              aspectRatio: aspectRatio,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Hero(
                      tag: imagePath,
                      child: Image.asset(
                        imagePath,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: Colors.grey[300],
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.broken_image, color: Colors.grey, size: 32),
                              SizedBox(height: 8),
                              Text(
                                'Image not found',
                                style: TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 12,
                    left: 12,
                    child: _buildThemeBadge(),
                  ),
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: InkWell(
                      onTap: () => _removeFavorite(imagePath),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.45),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          Icons.favorite,
                          color: Colors.redAccent,
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

  Widget _buildThemeBadge() {
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

  bool _isSquarePreview(String path) {
    final segments = path.split('/');
    if (segments.length > 4) {
      final possibleCategory = segments[3];
      if (possibleCategory == 'profile') {
        return true;
      }
      if (segments.length > 5 && segments[4] == 'profile') {
        return true;
      }
    }
    return false;
  }

  String _deriveThemeAssetPath(String previewPath) {
    if (previewPath.contains('/thumbnails/')) {
      return previewPath.replaceFirst('/thumbnails/', '/keyboard_themes/');
    }
    return previewPath;
  }

  @override
  Widget build(BuildContext context) {
    final adService = Provider.of<AdService>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Favorites',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Top Banner Ad
          Container(
            padding: EdgeInsets.all(8),
            child: adService.createBannerAdWidget(),
          ),
          // Content
          Expanded(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Loading favorites...',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : FadeTransition(
                    opacity: _fadeAnimation,
                    child: _favorites.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            onRefresh: _loadFavorites,
                            child: _buildFavoritesList(),
                          ),
                  ),
          ),
          // Bottom Banner Ad
          Container(
            padding: EdgeInsets.all(8),
            child: adService.createBannerAdWidget(),
          ),
        ],
      ),
    );
  }
}
