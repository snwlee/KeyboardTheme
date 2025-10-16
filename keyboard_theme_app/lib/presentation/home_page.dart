import 'package:flutter/material.dart';

import '../flavors/flavor_config.dart';
import '../l10n/app_localizations.dart';
import '../models/keyboard_theme.dart';
import 'theme_detail_page.dart';
import 'widgets/keyboard_theme_preview.dart';

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
    final keyboardThemes = config.keyboardThemes;

    return Scaffold(
      appBar: AppBar(
        title: Text(config.appName),
        backgroundColor: config.primaryColor.withOpacity(0.15),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Text(
            l10n.homeMessage,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 18),
          _LanguageSelectorCard(
            supportedLocales: supportedLocales,
            activeLocale: activeLocale,
            onLocaleSelected: onLocaleSelected,
          ),
          const SizedBox(height: 28),
          Text(
            'Keyboard Themes',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          if (keyboardThemes.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Text(
                'No keyboard themes configured for this flavor.',
                style: theme.textTheme.bodyMedium,
              ),
            )
          else
            ...keyboardThemes.map(
              (themeData) => _ThemeCard(
                config: config,
                themeData: themeData,
              ),
            ),
          const SizedBox(height: 24),
          _FlavorMetaCard(config: config),
          const SizedBox(height: 16),
          _LocaleListCard(locales: config.keyboardLocales),
          const SizedBox(height: 16),
          _AdMobCard(
            appId: config.admobAppId,
            bannerId: config.admobBannerId,
            interstitialId: config.admobInterstitialId,
          ),
        ],
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  const _ThemeCard({
    required this.config,
    required this.themeData,
  });

  final FlavorConfig config;
  final KeyboardThemeData themeData;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 20),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ThemeDetailPage(
                config: config,
                themeData: themeData,
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 280,
              child: KeyboardThemePreview(
                theme: themeData,
                heroTag: themeData.id,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 6),
              child: Text(
                themeData.name,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (themeData.description != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                child: Text(
                  themeData.description!,
                  style: textTheme.bodyMedium,
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
              child: Row(
                children: [
                  _ColorSwatch(label: 'Base', color: themeData.keyColor),
                  const SizedBox(width: 12),
                  _ColorSwatch(label: 'Accent', color: themeData.accentColor),
                  const Spacer(),
                  const Icon(Icons.chevron_right, color: Colors.white70),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LanguageSelectorCard extends StatelessWidget {
  const _LanguageSelectorCard({
    required this.supportedLocales,
    required this.activeLocale,
    required this.onLocaleSelected,
  });

  final List<Locale> supportedLocales;
  final Locale activeLocale;
  final ValueChanged<Locale?> onLocaleSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
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
              onChanged: onLocaleSelected,
            ),
          ],
        ),
      ),
    );
  }
}

class _FlavorMetaCard extends StatelessWidget {
  const _FlavorMetaCard({required this.config});

  final FlavorConfig config;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Flavor metadata',
              style: textTheme.titleSmall,
            ),
            const SizedBox(height: 10),
            Text('Flavor key: ${config.flavorName}'),
            Text('Package: ${config.packageName}'),
            Text('Assets root: ${config.assetPrefix}'),
          ],
        ),
      ),
    );
  }
}

class _LocaleListCard extends StatelessWidget {
  const _LocaleListCard({required this.locales});

  final List<Locale> locales;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
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
            ...locales.map(
              (locale) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.language),
                title: Text(_localeLabel(locale)),
                subtitle: Text(locale.toLanguageTag()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdMobCard extends StatelessWidget {
  const _AdMobCard({
    required this.appId,
    required this.bannerId,
    required this.interstitialId,
  });

  final String appId;
  final String bannerId;
  final String interstitialId;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'AdMob configuration',
              style: textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            _AdMobRow(label: 'App ID', value: appId),
            _AdMobRow(label: 'Banner ID', value: bannerId),
            _AdMobRow(label: 'Interstitial ID', value: interstitialId),
            const SizedBox(height: 8),
            Text(
              'Replace the placeholder values above with production IDs.',
              style: textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
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

class _ColorSwatch extends StatelessWidget {
  const _ColorSwatch({
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 24,
          width: 24,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
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
