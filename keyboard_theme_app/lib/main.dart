import 'package:flutter/foundation.dart';

import 'bootstrap.dart';
import 'flavors/flavor_config.dart';

Future<void> main() async {
  try {
    final config = await FlavorConfig.fromPlatform();
    await bootstrap(config);
  } catch (error, stackTrace) {
    debugPrint(
      'Failed to load flavor configuration: $error\n$stackTrace',
    );
    rethrow;
  }
}
