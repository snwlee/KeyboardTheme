import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class NativeAdWidget extends StatefulWidget {
  final String adUnitId;
  final double height;

  const NativeAdWidget({
    Key? key,
    required this.adUnitId,
    this.height = 320,
  }) : super(key: key);

  @override
  State<NativeAdWidget> createState() => _NativeAdWidgetState();
}

class _NativeAdWidgetState extends State<NativeAdWidget> {
  NativeAd? _nativeAd;
  bool _isAdLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() async {
    // Check consent status before loading ads
    try {
      final consentStatus = await ConsentInformation.instance.getConsentStatus();
      if (consentStatus != ConsentStatus.obtained && consentStatus != ConsentStatus.notRequired) {
        debugPrint('Skipping native ad load: Consent not obtained (status: $consentStatus)');
        return;
      }
    } catch (e) {
      debugPrint('Error checking consent status for native ad: $e');
      return;
    }

    _nativeAd = NativeAd(
      adUnitId: widget.adUnitId,
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          debugPrint('Native ad loaded successfully');
          if (mounted) {
            setState(() {
              _isAdLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Native ad failed to load: ${error.message}');
          ad.dispose();
          if (mounted) {
            setState(() {
              _isAdLoaded = false;
            });
          }
        },
        onAdOpened: (ad) {
          debugPrint('Native ad opened');
        },
        onAdClosed: (ad) {
          debugPrint('Native ad closed');
        },
      ),
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.medium,
        mainBackgroundColor: Colors.white,
        cornerRadius: 12.0,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          backgroundColor: Colors.blue,
          style: NativeTemplateFontStyle.bold,
          size: 16.0,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.black,
          backgroundColor: Colors.transparent,
          style: NativeTemplateFontStyle.bold,
          size: 16.0,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.grey,
          backgroundColor: Colors.transparent,
          style: NativeTemplateFontStyle.normal,
          size: 14.0,
        ),
        tertiaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.grey,
          backgroundColor: Colors.transparent,
          style: NativeTemplateFontStyle.normal,
          size: 12.0,
        ),
      ),
    )..load();
  }

  @override
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdLoaded || _nativeAd == null) {
      // Return a placeholder or empty container while loading
      return SizedBox(
        height: widget.height,
        child: Card(
          clipBehavior: Clip.antiAlias,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }

    return SizedBox(
      height: widget.height,
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: AdWidget(ad: _nativeAd!),
      ),
    );
  }
}
