import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'app/app.dart';
import 'flavors/flavor_config.dart';

Future<void> bootstrap(FlavorConfig config) async {
  WidgetsFlutterBinding.ensureInitialized();
  FlavorConfig.load(config);

  if (!kIsWeb) {
    await MobileAds.instance.initialize();
  }

  runApp(KeyboardThemeApp(config: config));
}
