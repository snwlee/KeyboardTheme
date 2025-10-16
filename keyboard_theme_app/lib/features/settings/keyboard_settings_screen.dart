import 'package:flutter/material.dart';
import 'package:wallpaperengine/core/services/keyboard_locale_service.dart';

class KeyboardLanguage {
  final String tag;
  final String name;
  final String description;

  const KeyboardLanguage({
    required this.tag,
    required this.name,
    required this.description,
  });
}

const _availableLanguages = <KeyboardLanguage>[
  KeyboardLanguage(tag: 'en_US', name: 'English', description: 'QWERTY layout'),
  KeyboardLanguage(tag: 'ko_KR', name: '한국어', description: '한글 두벌식 키보드'),
  KeyboardLanguage(tag: 'ja_JP', name: '日本語', description: 'かな 키보드 (가타카나/ひらがな)'),
  KeyboardLanguage(tag: 'es_ES', name: 'Español', description: 'Teclado español'),
  KeyboardLanguage(tag: 'fr_FR', name: 'Français', description: 'Clavier AZERTY français'),
  KeyboardLanguage(tag: 'de_DE', name: 'Deutsch', description: 'Deutsches QWERTZ'),
];

class KeyboardSettingsScreen extends StatefulWidget {
  const KeyboardSettingsScreen({super.key});

  @override
  State<KeyboardSettingsScreen> createState() => _KeyboardSettingsScreenState();
}

class _KeyboardSettingsScreenState extends State<KeyboardSettingsScreen> {
  final KeyboardLocaleService _localeService = KeyboardLocaleService();
  final Set<String> _selected = <String>{};
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadSelections();
  }

  Future<void> _loadSelections() async {
    final locales = await _localeService.getEnabledLocales();
    if (!mounted) return;
    setState(() {
      _selected
        ..clear()
        ..addAll(locales);
      _loading = false;
    });
  }

  void _toggleLanguage(String tag, bool value) {
    setState(() {
      if (value) {
        _selected.add(tag);
      } else {
        if (tag == 'en_US') {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('English keyboard cannot be disabled.')),
          );
          return;
        }
        if (_selected.length == 1) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('At least one keyboard must remain enabled.')),
          );
          return;
        }
        _selected.remove(tag);
      }
    });
  }

  Future<void> _saveSelections() async {
    if (_saving) return;
    if (!_selected.contains('en_US')) {
      _selected.add('en_US');
    }
    setState(() {
      _saving = true;
    });
    final ordered = _availableLanguages
        .where((lang) => _selected.contains(lang.tag))
        .map((lang) => lang.tag)
        .toList();
    try {
      await _localeService.setEnabledLocales(ordered);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Keyboard languages updated. Reopen the keyboard to apply.')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Keyboard Languages'),
        actions: [
          TextButton(
            onPressed: _saving || _loading ? null : _saveSelections,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text(
                    'Select the keyboards you want to use. English is always available as a fallback.',
                  ),
                ),
                Expanded(
                  child: ListView.separated(
                    itemCount: _availableLanguages.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final language = _availableLanguages[index];
                      final selected = _selected.contains(language.tag);
                      return CheckboxListTile(
                        value: selected,
                        onChanged: (value) {
                          if (value == null) return;
                          _toggleLanguage(language.tag, value);
                        },
                        title: Text(language.name),
                        subtitle: Text(language.description),
                        controlAffinity: ListTileControlAffinity.leading,
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
