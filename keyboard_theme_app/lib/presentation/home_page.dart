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
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  const SizedBox(height: 24),
                  Text(
                    'Keyboard Themes',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            ),
          ),
          if (keyboardThemes.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Text(
                  'No keyboard themes configured for this flavor.',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 18,
                  childAspectRatio: 0.7,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final themeData = keyboardThemes[index];
                    return _ThemeCard(
                      config: config,
                      themeData: themeData,
                    );
                  },
                  childCount: keyboardThemes.length,
                ),
              ),
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
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: KeyboardThemePreview(
                  theme: themeData,
                  heroTag: themeData.id,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: Text(
                themeData.name,
                style: textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            if (themeData.description != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Text(
                  themeData.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall,
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  _ColorChip(color: themeData.keyColor),
                  const SizedBox(width: 8),
                  _ColorChip(color: themeData.accentColor),
                  const Spacer(),
                  const Icon(Icons.chevron_right_rounded, color: Colors.white70),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ColorChip extends StatelessWidget {
  const _ColorChip({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 18,
      width: 18,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Colors.white.withOpacity(0.35),
          width: 1,
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.language, color: Colors.white70),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Interface Language',
                    style: theme.textTheme.titleSmall,
                  ),
                  Text(
                    _localeLabel(activeLocale),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            DropdownButtonHideUnderline(
              child: DropdownButton<Locale>(
                value: supportedLocales.contains(activeLocale)
                    ? activeLocale
                    : supportedLocales.first,
                dropdownColor: Colors.black87,
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
            ),
          ],
        ),
      ),
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
