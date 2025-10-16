package com.example.wallpaper_engine.ui

data class KeyboardKey(
    val label: String,
    val value: String = label,
    val type: KeyType = KeyType.CHARACTER,
    val weight: Float = 1f,
    val isActive: Boolean = false
)

enum class KeyType {
    CHARACTER,
    SPACE,
    DELETE,
    ENTER,
    SHIFT,
    SYMBOL_TOGGLE,
    LANGUAGE,
    EMOJI_TOGGLE
}
