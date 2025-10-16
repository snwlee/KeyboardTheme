import 'package:flutter/material.dart';

import '../flavors/flavor_config.dart';
import '../l10n/app_localizations.dart';

class HomePage extends StatelessWidget {
  const HomePage({
    super.key,
    required this.config,
    required this.onLocaleSelected,
    required this.currentLocale,
  });

  final FlavorConfig config;
  final ValueChanged<Locale?> onLocaleSelected;
  final Locale? currentLocale;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final supportedLocales = AppLocalizations.supportedLocales;
    final activeLocale = currentLocale ?? Localizations.localeOf(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.homeTitle),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            l10n.homeMessage,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Interface Language',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 12),
                  DropdownButton<Locale>(
                    value: supportedLocales.contains(activeLocale)
                        ? activeLocale
                        : supportedLocales.first,
                    items: supportedLocales
                        .map(
                          (locale) => DropdownMenuItem<Locale>(
                            value: locale,
                            child: Text(_localeLabel(locale)),
                          ),
                        )
                        .toList(),
                    onChanged: (locale) {
                      if (locale != null) {
                        onLocaleSelected(locale);
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Flavor metadata',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  Text('Flavor key: ${config.flavorName}'),
                  Text('App name: ${config.appName}'),
                  Text('Package: ${config.packageName}'),
                  Text('Assets root: ${config.assetPrefix}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Keyboard layouts',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  ...config.keyboardLocales.map(
                    (locale) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(_localeLabel(locale)),
                      subtitle: Text(locale.toLanguageTag()),
                      leading: const Icon(Icons.language),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AdMob configuration',
                    style: theme.textTheme.titleSmall,
                  ),
                  const SizedBox(height: 8),
                  _AdMobRow(label: 'App ID', value: config.admobAppId),
                  _AdMobRow(label: 'Banner ID', value: config.admobBannerId),
                  _AdMobRow(
                    label: 'Interstitial ID',
                    value: config.admobInterstitialId,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Replace the placeholder values above with production IDs.',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _localeLabel(Locale locale) {
    switch (locale.languageCode) {
      case 'ko':
        return '한국어';
      case 'en':
        return 'English';
      case 'ja':
        return '日本語';
      case 'th':
        return 'ภาษาไทย';
      default:
        return locale.languageCode;
    }
  }
}

class _AdMobRow extends StatelessWidget {
  const _AdMobRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: theme.textTheme.bodySmall,
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
