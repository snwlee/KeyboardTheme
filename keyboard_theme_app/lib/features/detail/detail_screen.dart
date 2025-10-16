import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:wallpaperengine/core/services/keyboard_theme_service.dart';
import 'package:wallpaperengine/core/services/ad_service.dart';
import 'package:wallpaperengine/core/services/download_service.dart';
import 'package:wallpaperengine/services/favorites_service.dart';
import 'package:wallpaperengine/services/detail_view_counter_service.dart';

class DetailScreen extends StatefulWidget {
  final String imageUrl;
  final String themeAssetPath;

  const DetailScreen({
    Key? key,
    required this.imageUrl,
    required this.themeAssetPath,
  }) : super(key: key);

  @override
  _DetailScreenState createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> with WidgetsBindingObserver {
  bool _isLoading = false;
  bool _isFavorite = false;
  bool _isKeyboardEnabled = false;
  bool _isKeyboardSelected = false;
  bool _hasPromptedKeyboardActivation = false;
  final FavoritesService _favoritesService = FavoritesService();
  final KeyboardThemeService _keyboardThemeService = KeyboardThemeService();
  final TextEditingController _previewController = TextEditingController();
  final FocusNode _previewFocusNode = FocusNode();

  String get _effectiveThemeAssetPath {
    final path = widget.themeAssetPath;
    if (path.isEmpty) {
      return widget.imageUrl;
    }
    return path;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkFavoriteStatus();
    _refreshKeyboardStatus();

    // Preload interstitial ad when entering detail screen
    // This ensures ad is ready when the user applies a keyboard theme
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final adService = Provider.of<AdService>(context, listen: false);
      if (!adService.isInterstitialAdReady) {
        debugPrint('Preloading interstitial ad for keyboard theme application');
      }
    });
  }

  void _showKeyboardActivationSheet() {
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 50,
                    height: 5,
                    margin: EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Text(
                  'Finish Keyboard Setup',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  _isKeyboardEnabled && _isKeyboardSelected
                      ? 'All set! Your keyboard theme is ready to use.'
                      : !_isKeyboardEnabled
                          ? 'Turn on the Keyboard Theme input method in system settings.'
                          : 'Choose Keyboard Theme as your active keyboard.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 24),
                _buildOptionTile(
                  icon: Icons.settings,
                  title: 'Enable in Settings',
                  subtitle: 'Open system settings to activate the keyboard',
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _openKeyboardSettings();
                  },
                ),
                _buildOptionTile(
                  icon: Icons.keyboard,
                  title: 'Switch Keyboard',
                  subtitle: 'Pick Keyboard Theme as the current input',
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _showKeyboardPicker();
                  },
                ),
                _buildOptionTile(
                  icon: Icons.refresh,
                  title: 'Refresh Status',
                  subtitle: 'Check if the keyboard is ready',
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _refreshKeyboardStatus().then((_) {
                      if (!_isKeyboardEnabled || !_isKeyboardSelected) {
                        _showInfoSnackBar(
                          'Keyboard not ready yet. Enable and select it to continue.',
                        );
                      } else {
                        _showInfoSnackBar('Keyboard Theme is active.');
                      }
                    });
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openKeyboardSettings() async {
    try {
      await _keyboardThemeService.openKeyboardSettings();
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('Unable to open keyboard settings.');
    }
  }

  Future<void> _showKeyboardPicker() async {
    try {
      await _keyboardThemeService.showKeyboardPicker();
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('Unable to show keyboard picker.');
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white),
            SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showInfoSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _showKeyboardPreview() {
    if (!_isKeyboardEnabled || !_isKeyboardSelected) {
      _showKeyboardActivationSheet();
      return;
    }

    _previewController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return GestureDetector(
          onTap: () => FocusScope.of(sheetContext).unfocus(),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
            ),
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 50,
                    height: 5,
                    margin: EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                Text(
                  'Try the Keyboard Theme',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Type below to preview how your keyboard looks with this theme.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[700],
                  ),
                ),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _previewController,
                    focusNode: _previewFocusNode,
                    autofocus: true,
                    style: TextStyle(fontSize: 16),
                    maxLines: 3,
                    minLines: 1,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Start typing here…',
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(sheetContext).pop(),
                    child: Text('Done'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).whenComplete(() {
      _previewFocusNode.unfocus();
    });
  }

  Future<void> _checkFavoriteStatus() async {
    final isFav = await _favoritesService.isFavorite(widget.imageUrl);
    setState(() {
      _isFavorite = isFav;
    });
  }

  Future<void> _refreshKeyboardStatus() async {
    try {
      final enabled = await _keyboardThemeService.isKeyboardEnabled();
      final selected = await _keyboardThemeService.isKeyboardSelected();
      if (mounted) {
        setState(() {
          _isKeyboardEnabled = enabled;
          _isKeyboardSelected = selected;
          if (enabled && selected) {
            _hasPromptedKeyboardActivation = false;
          }
        });
      }
    } catch (e) {
      debugPrint('Failed to refresh keyboard status: $e');
    }
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
    WidgetsBinding.instance.removeObserver(this);
    _previewController.dispose();
    _previewFocusNode.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      _refreshKeyboardStatus();
    }
  }

  Future<void> _applyKeyboardTheme(String mode, String modeLabel) async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _keyboardThemeService.applyKeyboardTheme(
        _effectiveThemeAssetPath,
        mode: mode,
      );

      await _refreshKeyboardStatus();

      if (!mounted) return;

      final successMessage = mode == 'dark'
          ? 'Dark keyboard theme applied.'
          : 'Keyboard theme applied to $modeLabel successfully!';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  successMessage,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

      if ((!_isKeyboardEnabled || !_isKeyboardSelected) && !_hasPromptedKeyboardActivation) {
        setState(() {
          _hasPromptedKeyboardActivation = true;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _showKeyboardActivationSheet();
          }
        });
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text('Failed to apply keyboard theme.'),
              ),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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
                    'Download Theme',
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
                    subtitle: 'Download this keyboard theme',
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
      await DownloadService.downloadKeyboardTheme(_effectiveThemeAssetPath, context);

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
                Expanded(child: Text('Theme download failed: $e')),
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
              Text('Keyboard theme downloaded successfully!'),
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

  void _showKeyboardThemeOptions() {
    final AdService adService = Provider.of<AdService>(context, listen: false);

    // Show bottom sheet first (it will be behind the ad)
    _showKeyboardThemeOptionsBottomSheet();

    // Then show interstitial ad on top
    if (adService.isInterstitialAdReady) {
      debugPrint('Showing interstitial ad over keyboard theme options bottom sheet');
      // Add small delay to ensure bottom sheet is rendered first
      Future.delayed(Duration(milliseconds: 300), () {
        adService.showInterstitialAd(() {
          debugPrint('Interstitial ad closed, bottom sheet now visible');
          // Bottom sheet is already shown, no action needed
        });
      });
    } else {
      debugPrint('Interstitial ad not ready, showing keyboard theme options directly');
      // Bottom sheet is already shown, no ad needed
    }
  }

  void _showKeyboardThemeOptionsBottomSheet() {
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
                    'Apply Keyboard Theme',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 20),
                  _buildOptionTile(
                    icon: Icons.nightlight_outlined,
                    title: 'Dark Mode',
                    subtitle: 'Use this theme for the dark keyboard',
                    onTap: () {
                      Navigator.pop(context);
                      _applyKeyboardTheme('dark', 'Dark Mode');
                    },
                  ),
                  _buildOptionTile(
                    icon: Icons.gradient,
                    title: 'Normal Mode',
                    subtitle: 'Transparent (투명) keycaps so the background shows',
                    onTap: () {
                      Navigator.pop(context);
                      _applyKeyboardTheme('both', 'Normal Mode');
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
            // Background image showcased with wide aspect ratio
            Positioned.fill(
              child: Container(color: Colors.black),
            ),
            Positioned.fill(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset(
                      widget.imageUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),

            // Gradient Overlay - Simplified
            Positioned.fill(
              child: Container(
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
                            onPressed: _showKeyboardPreview,
                            onLongPress: _showDownloadOptions,
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
                            child: Icon(Icons.keyboard, size: 24),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _buildActionButton(
                            icon: Icons.keyboard_alt_rounded,
                            label: _isLoading ? 'Applying...' : 'Apply Theme',
                            onPressed: _isLoading ? null : _showKeyboardThemeOptions,
                            isPrimary: true,
                            isLoading: _isLoading,
                          ),
                        ),
                      ],
                    ),
                    if (!_isKeyboardEnabled || !_isKeyboardSelected)
                      Container(
                        margin: EdgeInsets.only(top: 16),
                        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.45),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.keyboard, color: Colors.white),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                !_isKeyboardEnabled
                                    ? 'Enable the Keyboard Theme input method to use this theme.'
                                    : 'Switch to Keyboard Theme to see your new look.',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: _showKeyboardActivationSheet,
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.white,
                              ),
                              child: Text(
                                _isKeyboardEnabled ? 'Switch' : 'Enable',
                              ),
                            ),
                          ],
                        ),
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
                          'Applying keyboard theme...',
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
