import 'bootstrap.dart';
import 'flavors/flavor_config.dart';

Future<void> main() async {
  const flavorName = String.fromEnvironment('FLAVOR', defaultValue: 'kpopdemon');
  final config = FlavorConfig.resolve(flavorName);
  await bootstrap(config);
}
