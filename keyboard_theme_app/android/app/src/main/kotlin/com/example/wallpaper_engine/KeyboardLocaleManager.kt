package com.example.wallpaper_engine

import android.content.SharedPreferences
import com.example.wallpaper_engine.ui.KeyboardLayouts
import java.util.Locale
import java.util.LinkedHashSet

object KeyboardLocaleManager {
    const val SELECTED_LOCALES_KEY = "selected_locales"

    fun getSelectedLocales(prefs: SharedPreferences): List<String> {
        val stored = prefs.getStringSet(SELECTED_LOCALES_KEY, null)
        if (stored.isNullOrEmpty()) {
            val defaults = determineDefaultLocales()
            saveSelectedLocales(prefs, defaults)
            return defaults
        }
        val orderedTags = KeyboardLayouts.allLocales.map { it.localeTag }
        val storedSet = stored.toSet()
        return orderedTags.filter { storedSet.contains(it) }.ifEmpty {
            determineDefaultLocales()
        }
    }

    fun saveSelectedLocales(prefs: SharedPreferences, locales: List<String>) {
        val english = KeyboardLayouts.englishLocaleTag()
        val availableTags = KeyboardLayouts.allLocales.map { it.localeTag }
        val unique = LinkedHashSet<String>()
        unique.add(english)
        locales.forEach { tag ->
            if (availableTags.contains(tag)) {
                unique.add(tag)
            }
        }
        val finalList = availableTags.filter { unique.contains(it) }
            .ifEmpty { determineDefaultLocales() }
        prefs.edit().putStringSet(SELECTED_LOCALES_KEY, finalList.toSet()).apply()
    }

    fun determineDefaultLocales(): List<String> {
        val english = KeyboardLayouts.englishLocaleTag()
        val deviceLocale = currentDeviceLocale()
        val language = deviceLocale.language
        val userLocale = KeyboardLayouts.findByLanguage(language)

        return if (userLocale == null || userLocale.localeTag == english) {
            listOf(english)
        } else {
            listOf(english, userLocale.localeTag)
        }
    }

    fun currentDeviceLocale(): Locale = Locale.getDefault()

    fun ensureSelectionsValid(prefs: SharedPreferences) {
        val selections = getSelectedLocales(prefs)
        if (selections.isEmpty()) {
            saveSelectedLocales(prefs, determineDefaultLocales())
        }
    }
}
