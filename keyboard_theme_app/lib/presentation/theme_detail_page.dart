import 'package:flutter/material.dart';

import '../flavors/flavor_config.dart';
import '../models/keyboard_theme.dart';
import 'widgets/keyboard_theme_preview.dart';

class ThemeDetailPage extends StatelessWidget {
  const ThemeDetailPage({
    super.key,
    required this.config,
    required this.themeData,
  });

  final FlavorConfig config;
  final KeyboardThemeData themeData;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(themeData.name),
        backgroundColor: config.primaryColor.withOpacity(0.15),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          SizedBox(
            height: 420,
            child: KeyboardThemePreview(
              theme: themeData,
              heroTag: themeData.id,
            ),
          ),
          const SizedBox(height: 24),
          if (themeData.description != null) ...[
            Text(
              themeData.description!,
              style: textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
          ],
          Text(
            'Key colours',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 14,
            runSpacing: 12,
            children: [
              _ColorSwatch(label: 'Background', color: themeData.backgroundColor),
              _ColorSwatch(label: 'Primary keys', color: themeData.keyColor),
              _ColorSwatch(label: 'Secondary', color: themeData.secondaryKeyColor),
              _ColorSwatch(label: 'Accent', color: themeData.accentColor),
              _ColorSwatch(label: 'Text', color: themeData.keyTextColor),
            ],
          ),
          if (themeData.backgroundImageAsset != null) ...[
            const SizedBox(height: 16),
            Text(
              'Background asset: ${themeData.backgroundImageAsset}',
              style: textTheme.bodySmall,
            ),
          ],
          const SizedBox(height: 28),
          Text(
            'Supported keyboard layouts',
            style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: config.keyboardLocales
                .map(
                  (locale) => Chip(
                    label: Text(_localeLabel(locale)),
                    backgroundColor: config.primaryColor.withOpacity(0.15),
                    labelStyle: textTheme.bodySmall?.copyWith(
                      color: Colors.white,
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 28),
          Text(
            'Package',
            style: textTheme.titleSmall,
          ),
          const SizedBox(height: 6),
          SelectableText(
            config.packageName,
            style: textTheme.bodyMedium,
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 0, 20, 20),
        child: FilledButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${themeData.name} 적용 준비 중입니다.'),
                duration: const Duration(seconds: 2),
              ),
            );
          },
          icon: const Icon(Icons.brush_outlined),
          label: const Text('테마 적용'),
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            backgroundColor: config.primaryColor.withOpacity(0.9),
          ),
        ),
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
          height: 30,
          width: 30,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: Colors.white.withOpacity(0.32),
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
