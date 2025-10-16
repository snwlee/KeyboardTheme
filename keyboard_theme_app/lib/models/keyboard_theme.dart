import 'package:flutter/material.dart';

class KeyboardThemeData {
  const KeyboardThemeData({
    required this.id,
    required this.name,
    required this.backgroundColor,
    required this.keyColor,
    required this.keyTextColor,
    required this.secondaryKeyColor,
    required this.accentColor,
    required this.backgroundImageAsset,
    this.description,
  });

  final String id;
  final String name;
  final String? description;
  final Color backgroundColor;
  final Color keyColor;
  final Color secondaryKeyColor;
  final Color accentColor;
  final Color keyTextColor;
  final String? backgroundImageAsset;

  KeyboardThemeData copyWith({
    String? name,
    String? description,
    Color? backgroundColor,
    Color? keyColor,
    Color? secondaryKeyColor,
    Color? accentColor,
    Color? keyTextColor,
    String? backgroundImageAsset,
  }) {
    return KeyboardThemeData(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      keyColor: keyColor ?? this.keyColor,
      secondaryKeyColor: secondaryKeyColor ?? this.secondaryKeyColor,
      accentColor: accentColor ?? this.accentColor,
      keyTextColor: keyTextColor ?? this.keyTextColor,
      backgroundImageAsset: backgroundImageAsset ?? this.backgroundImageAsset,
    );
  }
}
