import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'bootstrap.dart';
import 'flavors/flavor_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final config = await FlavorConfig.fromPlatform();
    await bootstrap(config);
  } catch (error, stackTrace) {
    debugPrint(
      'Failed to load flavor configuration: $error\n$stackTrace',
    );
    runApp(const _ConfigurationErrorApp());
  }
}

class _ConfigurationErrorApp extends StatelessWidget {
  const _ConfigurationErrorApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
                SizedBox(height: 16),
                Text(
                  'Unable to load flavor configuration.\n'
                  'Ensure Android flavor config JSON files are present and rebuild.',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
      theme: ThemeData.dark(),
    );
  }
}
