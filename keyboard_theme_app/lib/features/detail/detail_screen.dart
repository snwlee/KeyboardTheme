import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:wallpaperengine/core/services/wallpaper_service.dart';
import 'package:wallpaperengine/core/services/ad_service.dart';
import 'package:wallpaperengine/core/services/download_service.dart';
import 'package:wallpaperengine/services/favorites_service.dart';
import 'package:wallpaperengine/services/detail_view_counter_service.dart';

class DetailScreen extends StatefulWidget {
  final String imageUrl;

  const DetailScreen({
    Key? key,
    required this.imageUrl,
  }) : super(key: key);

  @override
  _DetailScreenState createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  bool _isLoading = false;
  bool _isFavorite = false;
  final FavoritesService _favoritesService = FavoritesService();

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();

    // Preload interstitial ad when entering detail screen
    // This ensures ad is ready when user sets wallpaper
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final adService = Provider.of<AdService>(context, listen: false);
      if (!adService.isInterstitialAdReady) {
        debugPrint('Preloading interstitial ad for wallpaper setting');
      }
    });
  }

  Future<void> _checkFavoriteStatus() async {
    final isFav = await _favoritesService.isFavorite(widget.imageUrl);
    setState(() {
      _isFavorite = isFav;
    });
  }

  Future<void> _toggleFavorite() async {
    final newStatus = await _favoritesService.toggleFavorite(widget.imageUrl);
    setState(() {
      _isFavorite = newStatus;
    });

    // Show feedback
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              newStatus ? Icons.favorite : Icons.heart_broken,
              color: Colors.white,
            ),
            SizedBox(width: 12),
            Text(newStatus ? 'Added to favorites' : 'Removed from favorites'),
          ],
        ),
        backgroundColor: newStatus ? Colors.red : Colors.orange,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: Duration(seconds: 1),
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<bool> _setWallpaper(int wallpaperType) async {
    if (!mounted) return false;

    setState(() {
      _isLoading = true;
    });

    try {
      final WallpaperService wallpaperService = WallpaperService();
      await wallpaperService.setWallpaper(widget.imageUrl, wallpaperType);
      return true;
    } catch (e) {
      // In case of an error, you might want to log it.
      debugPrint('Failed to set wallpaper: $e');
      return false;
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _applyWallpaper(int wallpaperType, String typeName) async {
    // Set wallpaper first
    final success = await _setWallpaper(wallpaperType);

    if (!mounted) return;

    // Show toast immediately after wallpaper setting completes
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('Wallpaper applied to $typeName successfully!')),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('Failed to set wallpaper.')),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }


  void _showDownloadOptions() {
    final AdService adService = Provider.of<AdService>(context, listen: false);

    // 1. 광고 보고 다운로드 여부 선택
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 5,
              margin: EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 40),
              child: Column(
                children: [
                  Text(
                    'Download Wallpaper',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 20),
                  _buildOptionTile(
                    icon: Icons.download_rounded,
                    title: 'Download',
                    subtitle: 'Download this wallpaper',
                    onTap: () async {
                      Navigator.pop(context);
                      // 2. 다운로드 수행
                      await _performDownload();
                    },
                  ),
                  _buildOptionTile(
                    icon: Icons.close,
                    title: 'Cancel',
                    subtitle: 'Go back without downloading',
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _performDownload() async {
    final AdService adService = Provider.of<AdService>(context, listen: false);

    try {
      // 2. 다운로드 수행
      await DownloadService.downloadWallpaper(widget.imageUrl, context);

      // 3. 보상형 광고 수행
      if (adService.isRewardedAdReady) {
        adService.showRewardedAd(
          onRewarded: () async {
            debugPrint('User watched rewarded ad after download');
            // onRewarded는 아무것도 하지 않음 (onAdClosed에서 토스트 표시)
          },
          onAdClosed: () {
            debugPrint('Rewarded ad closed after download');
            // 4. 광고 종료 후 성공 토스트 (한 번만 호출)
            _showDownloadSuccessToast();
          },
        );
      } else {
        // 광고 준비 안 됨 - 바로 성공 토스트
        debugPrint('Rewarded ad not ready, download completed without ad');
        _showDownloadSuccessToast();
      }
    } catch (e) {
      // 다운로드 실패 시 에러 토스트
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('Download failed: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  void _showDownloadSuccessToast() {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Wallpaper downloaded successfully!'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showWallpaperOptions() {
    final AdService adService = Provider.of<AdService>(context, listen: false);

    // Show bottom sheet first (it will be behind the ad)
    _showWallpaperOptionsBottomSheet();

    // Then show interstitial ad on top
    if (adService.isInterstitialAdReady) {
      debugPrint('Showing interstitial ad over wallpaper options bottom sheet');
      // Add small delay to ensure bottom sheet is rendered first
      Future.delayed(Duration(milliseconds: 300), () {
        adService.showInterstitialAd(() {
          debugPrint('Interstitial ad closed, bottom sheet now visible');
          // Bottom sheet is already shown, no action needed
        });
      });
    } else {
      debugPrint('Interstitial ad not ready, showing wallpaper options directly');
      // Bottom sheet is already shown, no ad needed
    }
  }

  void _showWallpaperOptionsBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 5,
              margin: EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, 20, 20, 40),
              child: Column(
                children: [
                  Text(
                    'Set as Wallpaper',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 20),
                  _buildOptionTile(
                    icon: Icons.home_outlined,
                    title: 'Home Screen',
                    subtitle: 'Set as home screen wallpaper',
                    onTap: () {
                      Navigator.pop(context);
                      _applyWallpaper(1, 'Home Screen');
                    },
                  ),
                  _buildOptionTile(
                    icon: Icons.lock_outline,
                    title: 'Lock Screen',
                    subtitle: 'Set as lock screen wallpaper',
                    onTap: () {
                      Navigator.pop(context);
                      _applyWallpaper(2, 'Lock Screen');
                    },
                  ),
                  _buildOptionTile(
                    icon: Icons.devices,
                    title: 'Both Screens',
                    subtitle: 'Set as wallpaper for both screens',
                    onTap: () {
                      Navigator.pop(context);
                      _applyWallpaper(3, 'Both Screens');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).primaryColor,
                  size: 24,
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey[400],
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleBackNavigation() async {
    final AdService adService = Provider.of<AdService>(context, listen: false);

    // 조회 횟수 체크 및 광고 표시 여부 확인
    final shouldShowAd = await DetailViewCounterService.shouldShowAd();

    // 먼저 메인 화면으로 이동
    Navigator.of(context).pop();

    if (shouldShowAd) {
      // 메인 화면으로 돌아간 후 광고 표시
      Future.delayed(Duration(milliseconds: 100), () {
        adService.showInterstitialAd(() {
          // 광고 종료 후 실행할 작업이 있으면 여기에 추가
        });
      });
    }
  }

  Future<bool> _onWillPop() async {
    if (_isLoading) {
      // 배경화면 설정 중에는 뒤로가기 방지
      return false;
    }
    await _handleBackNavigation();
    return false; // 이미 Navigator.pop()을 호출했으므로 false 반환
  }

  @override
  Widget build(BuildContext context) {
    final AdService adService = Provider.of<AdService>(context);

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Background Image
            Container(
              width: double.infinity,
              height: double.infinity,
              child: Image.asset(
                widget.imageUrl,
                fit: BoxFit.cover,
              ),
            ),

            // Gradient Overlay - Simplified
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black54,
                    Colors.transparent,
                    Colors.black87,
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),

            // Top Banner Ad
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top,
                  left: 8,
                  right: 8,
                  bottom: 8,
                ),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black87,
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: EdgeInsets.all(8),
                  child: adService.createBannerAdWidget(),
                ),
              ),
            ),

            // Top Bar (below ad)
            Positioned(
              top: MediaQuery.of(context).padding.top + 70, // Ad height + padding
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: IconButton(
                        icon: Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: _handleBackNavigation,
                      ),
                    ),
                    Spacer(),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: IconButton(
                        icon: Icon(
                          _isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: _isFavorite ? Colors.red : Colors.white,
                        ),
                        onPressed: _toggleFavorite,
                        tooltip: _isFavorite ? 'Remove from favorites' : 'Add to favorites',
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Action Bar
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black87,
                    ],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: () => _showDownloadOptions(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withOpacity(0.2),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(27),
                                side: BorderSide(color: Colors.white.withOpacity(0.3)),
                              ),
                              padding: EdgeInsets.zero,
                            ),
                            child: Icon(Icons.download_rounded, size: 24),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.wallpaper_rounded,
                            label: _isLoading ? 'Applying...' : 'Set Wallpaper',
                            onPressed: _isLoading ? null : _showWallpaperOptions,
                            isPrimary: true,
                            isLoading: _isLoading,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    // Bottom Banner Ad
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: adService.createBannerAdWidget(),
                    ),
                  ],
                ),
              ),
            ),

            // Loading Overlay
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: Container(
                    padding: EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Setting wallpaper...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required bool isPrimary,
    bool isLoading = false,
  }) {
    return Container(
      height: 54,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary
            ? Theme.of(context).primaryColor
            : Colors.white.withOpacity(0.2),
          foregroundColor: isPrimary ? Colors.white : Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(27),
            side: isPrimary 
              ? BorderSide.none 
              : BorderSide(color: Colors.white.withOpacity(0.3)),
          ),
        ),
        child: isLoading
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 20),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
      ),
    );
  }
}

