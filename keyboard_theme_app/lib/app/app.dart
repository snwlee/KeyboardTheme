import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../flavors/flavor_config.dart';
import '../l10n/app_localizations.dart';
import '../presentation/home_page.dart';

class KeyboardThemeApp extends StatefulWidget {
  const KeyboardThemeApp({super.key, required this.config});

  final FlavorConfig config;

  @override
  State<KeyboardThemeApp> createState() => _KeyboardThemeAppState();
}

class _KeyboardThemeAppState extends State<KeyboardThemeApp> {
  Locale? _overrideLocale;

  void _handleLocaleChanged(Locale? locale) {
    setState(() {
      _overrideLocale = locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: widget.config.appName,
      onGenerateTitle: (context) =>
          AppLocalizations.of(context)?.appTitle ?? widget.config.appName,
      locale: _overrideLocale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: widget.config.primaryColor,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: HomePage(
        config: widget.config,
        onLocaleSelected: _handleLocaleChanged,
        currentLocale: _overrideLocale,
      ),
    );
  }
}
