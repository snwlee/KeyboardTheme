import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class BannerAdWidget extends StatefulWidget {
  final String adUnitId;
  final AdSize adSize;

  const BannerAdWidget({
    Key? key,
    required this.adUnitId,
    this.adSize = AdSize.banner,
  }) : super(key: key);

  @override
  _BannerAdWidgetState createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  int _retryCount = 0;
  static const int _maxRetries = 3;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
  }

  void _loadBannerAd() async {
    // Wait for MobileAds SDK to be fully initialized
    // Add extra delay to avoid rate limiting when multiple banners load
    await Future.delayed(const Duration(seconds: 1));

    // Check consent status before loading banner ad
    try {
      final consentStatus = await ConsentInformation.instance.getConsentStatus();
      if (consentStatus != ConsentStatus.obtained && consentStatus != ConsentStatus.notRequired) {
        debugPrint('Skipping banner ad load: Consent not obtained (status: $consentStatus)');
        setState(() {
          _isAdLoaded = false;
        });
        return;
      }
    } catch (e) {
      debugPrint('Error checking consent status for banner ad: $e');
      setState(() {
        _isAdLoaded = false;
      });
      return;
    }

    debugPrint('Loading banner ad with ID: ${widget.adUnitId}');

    _bannerAd = BannerAd(
      adUnitId: widget.adUnitId,
      size: widget.adSize,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('✅ Banner ad loaded successfully');
          _retryCount = 0; // Reset retry count on success
          if (mounted) {
            setState(() {
              _isAdLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('❌ Banner ad failed to load: Code ${error.code}, Message: ${error.message}');
          debugPrint('   Domain: ${error.domain}, ResponseInfo: ${error.responseInfo}');
          ad.dispose();
          if (mounted) {
            setState(() {
              _isAdLoaded = false;
            });
          }

          // Retry with exponential backoff (max 3 times)
          if (_retryCount < _maxRetries) {
            _retryCount++;
            final retryDelay = Duration(seconds: 5 * _retryCount); // 5s, 10s, 15s
            debugPrint('Retrying banner ad load in ${retryDelay.inSeconds}s (attempt $_retryCount/$_maxRetries)...');
            Future.delayed(retryDelay, () {
              if (mounted) {
                _loadBannerAd();
              }
            });
          } else {
            debugPrint('Banner ad max retries reached. Giving up.');
          }
        },
        onAdOpened: (ad) {
          debugPrint('Banner ad opened');
        },
        onAdClosed: (ad) {
          debugPrint('Banner ad closed');
        },
      ),
    );

    _bannerAd!.load();
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdLoaded || _bannerAd == null) {
      return Container(
        width: widget.adSize.width.toDouble(),
        height: widget.adSize.height.toDouble(),
        color: Colors.grey[100],
        child: Center(
          child: Text(
            'Ad Loading...',
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
          ),
        ),
      );
    }

    return Container(
      alignment: Alignment.center,
      width: widget.adSize.width.toDouble(),
      height: widget.adSize.height.toDouble(),
      child: AdWidget(ad: _bannerAd!),
    );
  }
}