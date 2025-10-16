import 'package:flutter/material.dart';

import '../../models/keyboard_theme.dart';

class KeyboardThemePreview extends StatelessWidget {
  const KeyboardThemePreview({
    super.key,
    required this.theme,
    this.heroTag,
  });

  final KeyboardThemeData theme;
  final String? heroTag;

  static const List<List<String>> _keyRows = [
    ['Q', 'W', 'E', 'R', 'T', 'Y', 'U', 'I', 'O', 'P'],
    ['A', 'S', 'D', 'F', 'G', 'H', 'J', 'K', 'L'],
    ['Z', 'X', 'C', 'V', 'B', 'N', 'M'],
  ];

  @override
  Widget build(BuildContext context) {
    final content = _buildContent(context);
    if (heroTag != null) {
      return Hero(tag: heroTag!, child: content);
    }
    return content;
  }

  Widget _buildContent(BuildContext context) {
    final backgroundDecoration = BoxDecoration(
      color: theme.backgroundColor,
      borderRadius: BorderRadius.circular(32),
      image: theme.backgroundImageAsset != null
          ? DecorationImage(
              image: AssetImage(theme.backgroundImageAsset!),
              fit: BoxFit.cover,
              colorFilter: ColorFilter.mode(
                theme.accentColor.withOpacity(0.35),
                BlendMode.srcATop,
              ),
            )
          : null,
      boxShadow: [
        BoxShadow(
          color: theme.accentColor.withOpacity(0.3),
          blurRadius: 40,
          spreadRadius: 2,
          offset: const Offset(0, 18),
        ),
      ],
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 26),
      decoration: backgroundDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: theme.accentColor.withOpacity(0.25),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                theme.name.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.bold,
                      color: theme.keyTextColor.withOpacity(0.85),
                    ),
              ),
            ),
          ),
          const Spacer(),
          ..._keyRows.map(_buildRow),
          const SizedBox(height: 14),
          _buildSpaceRow(),
        ],
      ),
    );
  }

  Widget _buildRow(List<String> keys) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ...keys.map(
            (key) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _KeyCap(
                label: key,
                textColor: theme.keyTextColor,
                background: key == 'F' || key == 'J'
                    ? theme.accentColor
                    : theme.keyColor,
                highlight: key == 'F' || key == 'J'
                    ? theme.accentColor
                    : theme.secondaryKeyColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpaceRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _KeyCap(
          icon: Icons.emoji_emotions_outlined,
          background: theme.secondaryKeyColor,
          highlight: theme.accentColor,
          textColor: theme.keyTextColor,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              gradient: LinearGradient(
                colors: [
                  theme.secondaryKeyColor.withOpacity(0.9),
                  theme.keyColor,
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.accentColor.withOpacity(0.45),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              'SPACE',
              style: TextStyle(
                color: theme.keyTextColor.withOpacity(0.85),
                letterSpacing: 2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        _KeyCap(
          icon: Icons.backspace_outlined,
          background: theme.secondaryKeyColor,
          highlight: theme.accentColor,
          textColor: theme.keyTextColor,
        ),
      ],
    );
  }
}

class _KeyCap extends StatelessWidget {
  const _KeyCap({
    this.label,
    this.icon,
    required this.background,
    required this.highlight,
    required this.textColor,
  }) : assert(label != null || icon != null);

  final String? label;
  final IconData? icon;
  final Color background;
  final Color highlight;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      width: 46,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            highlight.withOpacity(0.85),
            background,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: highlight.withOpacity(0.45),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: icon != null
          ? Icon(icon, color: textColor.withOpacity(0.92), size: 22)
          : Text(
              label ?? '',
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w600,
                fontSize: 16,
                letterSpacing: 0.5,
              ),
            ),
    );
  }
}
