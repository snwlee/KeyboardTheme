import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:wallpaperengine/config/app_config.dart';
import 'package:wallpaperengine/widgets/banner_ad_widget.dart';
import 'package:wallpaperengine/widgets/native_ad_widget.dart';

class AdService {
  final AdMobSettings _admobSettings;

  InterstitialAd? _interstitialAd;
  RewardedAd? _rewardedAd;
  bool _isAdReady = false;
  bool _isRewardedAdReady = false;
  DateTime? _interstitialAdLoadTime;

  // Public getters to check ad status
  bool get isRewardedAdReady => _isRewardedAdReady;
  bool get isInterstitialAdReady => _isAdReady && !_isInterstitialAdExpired();

  // Cache durations (Google recommended)
  static const int _interstitialAdCacheDuration = 60 * 60 * 1000; // 1 hour

  // Constructor - inject AdMob settings
  AdService(this._admobSettings);

  void initialize() {
    _loadInterstitialAd();
    _loadRewardedAd();
  }

  // Check if interstitial ad cache is expired (1 hour - Google recommended)
  bool _isInterstitialAdExpired() {
    if (_interstitialAdLoadTime == null) {
      return true;
    }
    final now = DateTime.now();
    final difference = now.difference(_interstitialAdLoadTime!).inMilliseconds;
    return difference >= _interstitialAdCacheDuration;
  }

  void _loadInterstitialAd() async {
    // Check consent status before loading ads
    try {
      final consentStatus = await ConsentInformation.instance.getConsentStatus();
      if (consentStatus != ConsentStatus.obtained && consentStatus != ConsentStatus.notRequired) {
        debugPrint('Skipping ad load: Consent not obtained (status: $consentStatus)');
        return;
      }
    } catch (e) {
      debugPrint('Error checking consent status: $e');
      return;
    }

    final Completer<InterstitialAd> completer = Completer<InterstitialAd>();

    InterstitialAd.load(
      adUnitId: _admobSettings.interstitialAdUnitId,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          debugPrint('Interstitial ad loaded successfully');
          completer.complete(ad);
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('Interstitial ad failed to load: ${error.message}');
          completer.completeError(error);
        },
      ),
    );

    completer.future.timeout(const Duration(seconds: 10), onTimeout: () {
      debugPrint('Interstitial ad loading timed out.');
      throw TimeoutException('Interstitial ad loading timed out');
    }).then((ad) {
      _interstitialAd = ad;
      _isAdReady = true;
      _interstitialAdLoadTime = DateTime.now();

      _interstitialAd!.setImmersiveMode(true);
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (InterstitialAd ad) {
          ad.dispose();
          _isAdReady = false;
          _interstitialAdLoadTime = null;
          _loadInterstitialAd();
        },
        onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
          ad.dispose();
          _isAdReady = false;
          _interstitialAdLoadTime = null;
          _loadInterstitialAd();
        },
      );
    }).catchError((error) {
      // Silently handle timeout - don't log to reduce noise
      if (error is! TimeoutException) {
        debugPrint('Error loading interstitial ad: $error');
      }
      _isAdReady = false;
      _interstitialAdLoadTime = null;
      // Retry after delay
      Future.delayed(const Duration(seconds: 5), _loadInterstitialAd);
    });
  }

  void showInterstitialAd(VoidCallback onAdClosed) {
    // Check if ad is expired (Google best practice: reload after 1 hour)
    if (_isAdReady && _isInterstitialAdExpired()) {
      debugPrint('Interstitial ad expired (> 1 hour), reloading...');
      _interstitialAd?.dispose();
      _interstitialAd = null;
      _isAdReady = false;
      _interstitialAdLoadTime = null;
      _loadInterstitialAd();
      onAdClosed();
      return;
    }

    if (_isAdReady && _interstitialAd != null) {
      debugPrint('Showing interstitial ad...');
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (InterstitialAd ad) {
          debugPrint('Interstitial ad dismissed by user');
          ad.dispose();
          _isAdReady = false;
          _interstitialAdLoadTime = null;
          _loadInterstitialAd();
          onAdClosed();
        },
        onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
          debugPrint('Interstitial ad failed to show: ${error.message}');
          ad.dispose();
          _isAdReady = false;
          _interstitialAdLoadTime = null;
          _loadInterstitialAd();
          onAdClosed();
        },
      );
      _interstitialAd!.show();
    } else {
      debugPrint('Interstitial ad not ready (_isAdReady: $_isAdReady, _interstitialAd: ${_interstitialAd != null}), proceeding without ad');
      onAdClosed();
    }
  }

  BannerAd createBannerAd() {
    return BannerAd(
      adUnitId: _admobSettings.bannerAdUnitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('Banner ad loaded');
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('Banner ad failed to load: $error');
          ad.dispose();
        },
        onAdOpened: (ad) {
          debugPrint('Banner ad opened');
        },
        onAdClosed: (ad) {
          debugPrint('Banner ad closed');
        },
      ),
    );
  }

  Widget createBannerAdWidget() {
    return BannerAdWidget(adUnitId: _admobSettings.bannerAdUnitId);
  }

  Widget createNativeAdWidget({double height = 320}) {
    return NativeAdWidget(
      adUnitId: _admobSettings.nativeAdUnitId,
      height: height,
    );
  }

  void _loadRewardedAd() async {
    // Check consent status before loading ads
    try {
      final consentStatus = await ConsentInformation.instance.getConsentStatus();
      if (consentStatus != ConsentStatus.obtained && consentStatus != ConsentStatus.notRequired) {
        debugPrint('Skipping rewarded ad load: Consent not obtained (status: $consentStatus)');
        return;
      }
    } catch (e) {
      debugPrint('Error checking consent status for rewarded ad: $e');
      return;
    }

    RewardedAd.load(
      adUnitId: _admobSettings.rewardedAdUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (RewardedAd ad) {
          debugPrint('Rewarded ad loaded');
          _rewardedAd = ad;
          _isRewardedAdReady = true;

          _rewardedAd!.setImmersiveMode(true);
        },
        onAdFailedToLoad: (LoadAdError error) {
          debugPrint('Rewarded ad failed to load: $error');
          _isRewardedAdReady = false;
        },
      ),
    );
  }

  void showRewardedAd({
    required Future<void> Function() onRewarded,
    required VoidCallback onAdClosed,
  }) {
    if (_isRewardedAdReady && _rewardedAd != null) {
      bool rewardEarned = false;

      _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (RewardedAd ad) async {
          debugPrint('Rewarded ad dismissed, reward earned: $rewardEarned');
          ad.dispose();
          _isRewardedAdReady = false;
          _loadRewardedAd();

          // 광고를 보든 안 보든 항상 다운로드 실행
          await onRewarded();

          // onAdClosed도 호출하여 추가 로직 실행 가능
          onAdClosed();
        },
        onAdFailedToShowFullScreenContent: (RewardedAd ad, AdError error) async {
          debugPrint('Rewarded ad failed to show: $error');
          ad.dispose();
          _isRewardedAdReady = false;
          _loadRewardedAd();

          // 광고 표시 실패해도 다운로드 실행
          await onRewarded();
          onAdClosed();
        },
      );

      _rewardedAd!.show(
        onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
          debugPrint('User earned reward: ${reward.amount} ${reward.type}');
          rewardEarned = true;
        },
      );
    } else {
      debugPrint('Rewarded ad not ready, proceeding without ad');
      // 광고가 준비되지 않았으면 바로 다운로드
      onRewarded().then((_) => onAdClosed());
    }
  }

  void dispose() {
    _interstitialAd?.dispose();
    _rewardedAd?.dispose();
  }
}