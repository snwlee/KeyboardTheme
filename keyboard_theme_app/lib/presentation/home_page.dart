import 'package:flutter/material.dart';

import '../flavors/flavor_config.dart';
import '../l10n/app_localizations.dart';
import '../models/keyboard_theme.dart';
import 'widgets/keyboard_theme_preview.dart';

class HomePage extends StatefulWidget {
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
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final PageController _pageController;
  int _currentThemeIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.88);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final supportedLocales = AppLocalizations.supportedLocales;
    final activeLocale =
        widget.currentLocale ?? Localizations.localeOf(context);
    final keyboardThemes = widget.config.keyboardThemes;
    final selectedTheme = keyboardThemes.isNotEmpty
        ? keyboardThemes[_currentThemeIndex.clamp(
            0,
            keyboardThemes.length - 1,
          )]
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.config.appName),
        backgroundColor: widget.config.primaryColor.withOpacity(0.15),
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
            onLocaleSelected: widget.onLocaleSelected,
          ),
          const SizedBox(height: 28),
          Text(
            'Keyboard Themes',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          if (keyboardThemes.isNotEmpty) ...[
            SizedBox(
              height: 360,
              child: PageView.builder(
                controller: _pageController,
                itemCount: keyboardThemes.length,
                physics: keyboardThemes.length > 1
                    ? const BouncingScrollPhysics()
                    : const NeverScrollableScrollPhysics(),
                onPageChanged: (index) {
                  setState(() => _currentThemeIndex = index);
                },
                itemBuilder: (context, index) {
                  final themeData = keyboardThemes[index];
                  return AnimatedBuilder(
                    animation: _pageController,
                    builder: (context, child) {
                      double value = 1.0;
                      if (_pageController.position.haveDimensions) {
                        final page =
                            _pageController.page ?? _currentThemeIndex.toDouble();
                        value = page - index;
                        value = (1 - (value.abs() * 0.2)).clamp(0.85, 1.0);
                      } else {
                        value = index == _currentThemeIndex ? 1.0 : 0.9;
                      }
                      return Center(
                        child: SizedBox(
                          height: Curves.easeOut.transform(value) * 360,
                          child: child,
                        ),
                      );
                    },
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: index == _currentThemeIndex ? 8 : 16,
                      ),
                      child: KeyboardThemePreview(theme: themeData),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            if (keyboardThemes.length > 1)
              _ThemeIndicators(
                themes: keyboardThemes,
                activeIndex: _currentThemeIndex,
              ),
            if (selectedTheme != null) ...[
              const SizedBox(height: 16),
              _ThemeDescriptionCard(themeData: selectedTheme),
            ],
          ] else ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Text(
                'No keyboard themes configured for this flavor.',
                style: theme.textTheme.bodyMedium,
              ),
            ),
          ],
          const SizedBox(height: 24),
          _FlavorMetaCard(config: widget.config),
          const SizedBox(height: 16),
          _LocaleListCard(locales: widget.config.keyboardLocales),
          const SizedBox(height: 16),
          _AdMobCard(
            appId: widget.config.admobAppId,
            bannerId: widget.config.admobBannerId,
            interstitialId: widget.config.admobInterstitialId,
          ),
        ],
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

class _ThemeIndicators extends StatelessWidget {
  const _ThemeIndicators({
    required this.themes,
    required this.activeIndex,
  });

  final List<KeyboardThemeData> themes;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        themes.length,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.symmetric(horizontal: 6),
          height: 10,
          width: index == activeIndex ? 32 : 10,
          decoration: BoxDecoration(
            color: index == activeIndex
                ? themes[index].accentColor
                : themes[index].accentColor.withOpacity(0.25),
            borderRadius: BorderRadius.circular(24),
          ),
        ),
      ),
    );
  }
}

class _ThemeDescriptionCard extends StatelessWidget {
  const _ThemeDescriptionCard({required this.themeData});

  final KeyboardThemeData themeData;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              themeData.name,
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (themeData.description != null) ...[
              const SizedBox(height: 6),
              Text(
                themeData.description!,
                style: textTheme.bodyMedium,
              ),
            ],
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                _ColorSwatch(label: 'Background', color: themeData.backgroundColor),
                _ColorSwatch(label: 'Primary keys', color: themeData.keyColor),
                _ColorSwatch(label: 'Accent', color: themeData.accentColor),
                _ColorSwatch(label: 'Text', color: themeData.keyTextColor),
              ],
            ),
            if (themeData.backgroundImageAsset != null) ...[
              const SizedBox(height: 12),
              Text(
                'Background asset: ${themeData.backgroundImageAsset}',
                style: textTheme.bodySmall,
              ),
            ],
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
          height: 26,
          width: 26,
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
