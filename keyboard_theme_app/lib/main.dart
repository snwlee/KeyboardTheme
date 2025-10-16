import 'bootstrap.dart';
import 'flavors/flavor_config.dart';

Future<void> main() async {
  FlavorConfig config;
  try {
    config = await FlavorConfig.fromPlatform();
  } catch (_) {
    const fallbackFlavor =
        String.fromEnvironment('FLAVOR', defaultValue: 'main');
    config = FlavorConfig.fallback(fallbackFlavor);
  }
  await bootstrap(config);
}
