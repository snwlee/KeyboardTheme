import 'bootstrap.dart';
import 'flavors/flavor_config.dart';

Future<void> main() async {
  await bootstrap(FlavorConfig.presets['kpopdemon']!);
}
