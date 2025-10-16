import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:wallpaperengine/config/app_config.dart';
import 'package:wallpaperengine/core/services/ad_service.dart';
import 'package:wallpaperengine/core/services/consent_service.dart';
import 'package:wallpaperengine/core/services/review_service.dart';
import 'package:wallpaperengine/features/home/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 앱 실행 횟수 증가 및 리뷰 요청 체크
  final reviewService = ReviewService();
  await reviewService.incrementAppLaunchCount();

  // CRITICAL: Only essential initialization in main() to prevent ANR
  // Initialize AppConfig by loading the flavor-specific config.json from native.
  await AppConfig.initialize();

  // Balanced image cache limits to prevent OOM crashes (works on low-end devices)
  // Grid thumbnails should use cacheHeight/cacheWidth to stay within this limit
  PaintingBinding.instance.imageCache.maximumSize = 15; // Keep 15 images cached
  PaintingBinding.instance.imageCache.maximumSizeBytes = 15 << 20; // 15MB max

  // Create services WITHOUT initializing (deferred initialization)
  final consentService = ConsentService();

  runApp(
    MultiProvider(
      providers: [
        Provider<AppConfig>.value(value: AppConfig.instance),
        Provider<ConsentService>.value(value: consentService),
        Provider<AdService>(
          create: (_) => AdService(AppConfig.instance.admobSettings),
          dispose: (_, adService) => adService.dispose(),
        ),
      ],
      child: MyApp(
        appConfig: AppConfig.instance,
        consentService: consentService,
      ),
    ),
  );
}

class MyApp extends StatefulWidget {
  final AppConfig appConfig;
  final ConsentService consentService;

  const MyApp({
    Key? key,
    required this.appConfig,
    required this.consentService,
  }) : super(key: key);

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();

    // Deferred initialization: Run AFTER first frame to prevent ANR
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeServicesAsync();
    });
  }

  Future<void> _initializeServicesAsync() async {
    try {
      // CRITICAL: Must initialize in order for ads to work properly
      // 1. First get consent status
      await widget.consentService.initialize();

      // 2. Then initialize Mobile Ads SDK
      await MobileAds.instance.initialize();

      // 3. Finally initialize ad service (loads ads)
      final adService = Provider.of<AdService>(context, listen: false);
      adService.initialize();

      print('Deferred services initialized successfully');
    } catch (e) {
      print('Error initializing deferred services: $e');
      // Don't crash the app, services will work in degraded mode
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: widget.appConfig.appName,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        colorScheme: ColorScheme.fromSeed(seedColor: widget.appConfig.themeColor),
        brightness: Brightness.light,
        appBarTheme: AppBarTheme(
          surfaceTintColor: Colors.transparent,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.blue,
        colorScheme: ColorScheme.fromSeed(
          seedColor: widget.appConfig.themeColor,
          brightness: Brightness.dark,
        ),
        brightness: Brightness.dark,
        appBarTheme: AppBarTheme(
          surfaceTintColor: Colors.transparent,
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      themeMode: ThemeMode.system, // Or from settings
      home: HomeScreen(),
    );
  }
}
