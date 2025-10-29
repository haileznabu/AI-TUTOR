import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdService {
  static final AdService _instance = AdService._internal();
  factory AdService() => _instance;
  AdService._internal();

  static const String _androidBannerAdUnitId = 'ca-app-pub-3940256099942544/6300978111';
  static const String _androidInterstitialAdUnitId = 'ca-app-pub-3940256099942544/1033173712';

  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdReady = false;

  static Future<void> initialize() async {
    if (kIsWeb) {
      return;
    }
    try {
      await MobileAds.instance.initialize();
    } catch (e) {
      debugPrint('Ad initialization error: $e');
    }
  }

  static String get bannerAdUnitId {
    if (kIsWeb) {
      return '';
    }
    return _androidBannerAdUnitId;
  }

  static String get interstitialAdUnitId {
    if (kIsWeb) {
      return '';
    }
    return _androidInterstitialAdUnitId;
  }

  BannerAd? createBannerAd() {
    if (kIsWeb || bannerAdUnitId.isEmpty) {
      return null;
    }
    try {
      return BannerAd(
        adUnitId: bannerAdUnitId,
        size: AdSize.banner,
        request: const AdRequest(),
        listener: BannerAdListener(
          onAdLoaded: (ad) {},
          onAdFailedToLoad: (ad, error) {
            ad.dispose();
          },
        ),
      );
    } catch (e) {
      debugPrint('Banner ad creation error: $e');
      return null;
    }
  }

  void loadInterstitialAd({Function()? onAdLoaded}) {
    if (kIsWeb || interstitialAdUnitId.isEmpty) {
      return;
    }
    try {
      InterstitialAd.load(
        adUnitId: interstitialAdUnitId,
        request: const AdRequest(),
        adLoadCallback: InterstitialAdLoadCallback(
          onAdLoaded: (ad) {
            _interstitialAd = ad;
            _isInterstitialAdReady = true;
            onAdLoaded?.call();

            ad.fullScreenContentCallback = FullScreenContentCallback(
              onAdDismissedFullScreenContent: (ad) {
                ad.dispose();
                _interstitialAd = null;
                _isInterstitialAdReady = false;
              },
              onAdFailedToShowFullScreenContent: (ad, error) {
                ad.dispose();
                _interstitialAd = null;
                _isInterstitialAdReady = false;
              },
            );
          },
          onAdFailedToLoad: (error) {
            _isInterstitialAdReady = false;
          },
        ),
      );
    } catch (e) {
      debugPrint('Interstitial ad load error: $e');
    }
  }

  void showInterstitialAd({Function()? onAdClosed}) {
    if (kIsWeb) {
      onAdClosed?.call();
      return;
    }
    if (_isInterstitialAdReady && _interstitialAd != null) {
      try {
        _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
          onAdDismissedFullScreenContent: (ad) {
            ad.dispose();
            _interstitialAd = null;
            _isInterstitialAdReady = false;
            onAdClosed?.call();
            loadInterstitialAd();
          },
          onAdFailedToShowFullScreenContent: (ad, error) {
            ad.dispose();
            _interstitialAd = null;
            _isInterstitialAdReady = false;
            onAdClosed?.call();
          },
        );
        _interstitialAd!.show();
      } catch (e) {
        debugPrint('Interstitial ad show error: $e');
        onAdClosed?.call();
      }
    } else {
      onAdClosed?.call();
    }
  }

  void dispose() {
    _interstitialAd?.dispose();
    _interstitialAd = null;
    _isInterstitialAdReady = false;
  }
}
