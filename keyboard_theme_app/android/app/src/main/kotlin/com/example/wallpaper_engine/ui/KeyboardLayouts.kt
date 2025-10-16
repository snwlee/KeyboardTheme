package com.example.wallpaper_engine.ui

import java.util.Locale

data class KeyboardLocaleSpec(
    val localeTag: String,
    val displayLabel: String,
    val alphaRows: List<List<String>>,
    val spaceLabel: String,
    val enterLabel: String,
    val usesHangulComposer: Boolean = false
)

data class LayoutState(
    val isShifted: Boolean,
    val isSymbolMode: Boolean,
    val isEmojiVisible: Boolean,
    val isShiftLocked: Boolean = false
)
object KeyboardLayouts {

    val allLocales: List<KeyboardLocaleSpec> = listOf(
        KeyboardLocaleSpec(
            localeTag = "en_US",
            displayLabel = "EN",
            alphaRows = listOf(
                listOf("q","w","e","r","t","y","u","i","o","p"),
                listOf("a","s","d","f","g","h","j","k","l"),
                listOf("z","x","c","v","b","n","m")
            ),
            spaceLabel = "Space",
            enterLabel = "Enter"
        ),
        KeyboardLocaleSpec(
            localeTag = "es_ES",
            displayLabel = "ES",
            alphaRows = listOf(
                listOf("q","w","e","r","t","y","u","i","o","p"),
                listOf("a","s","d","f","g","h","j","k","l","ñ"),
                listOf("z","x","c","v","b","n","m")
            ),
            spaceLabel = "Espacio",
            enterLabel = "Intro"
        ),
        KeyboardLocaleSpec(
            localeTag = "fr_FR",
            displayLabel = "FR",
            alphaRows = listOf(
                listOf("a","z","e","r","t","y","u","i","o","p"),
                listOf("q","s","d","f","g","h","j","k","l","ç"),
                listOf("w","x","c","v","b","n","m")
            ),
            spaceLabel = "Espace",
            enterLabel = "Entrer"
        ),
        KeyboardLocaleSpec(
            localeTag = "de_DE",
            displayLabel = "DE",
            alphaRows = listOf(
                listOf("q","w","e","r","t","z","u","i","o","p","ü"),
                listOf("a","s","d","f","g","h","j","k","l","ö"),
                listOf("y","x","c","v","b","n","m","ß")
            ),
            spaceLabel = "Leertaste",
            enterLabel = "Enter"
        ),
        KeyboardLocaleSpec(
            localeTag = "ja_JP",
            displayLabel = "あA",
            alphaRows = listOf(
                listOf("あ","か","さ","た","な","は","ま","や","ら","わ"),
                listOf("い","う","え","お","し","ち","ほ","の","゛","゜"),
                listOf("る","ん","ー","。","、","？","！")
            ),
            spaceLabel = "空白",
            enterLabel = "確定"
        ),
        KeyboardLocaleSpec(
            localeTag = "ko_KR",
            displayLabel = "한/영",
            alphaRows = listOf(
                listOf("ㅂ","ㅈ","ㄷ","ㄱ","ㅅ","ㅛ","ㅕ","ㅑ","ㅐ","ㅔ"),
                listOf("ㅁ","ㄴ","ㅇ","ㄹ","ㅎ","ㅗ","ㅓ","ㅏ","ㅣ"),
                listOf("ㅋ","ㅌ","ㅊ","ㅍ","ㅠ","ㅜ","ㅡ")
            ),
            spaceLabel = "스페이스",
            enterLabel = "완료",
            usesHangulComposer = true
        )
    )

    private val symbolRows: List<List<String>> = listOf(
        listOf("1","2","3","4","5","6","7","8","9","0"),
        listOf("@","#","$","%","&","*","-","+","(",")"),
        listOf("~","`","\\","/",";",":","\"","'","?")
    )

    private val localeByTag: Map<String, KeyboardLocaleSpec> = allLocales.associateBy { it.localeTag }

    fun englishLocaleTag(): String = "en_US"

    fun resolveLocales(selectedTags: Collection<String>): List<KeyboardLocaleSpec> {
        val resolved = selectedTags.mapNotNull { localeByTag[it] }
        if (resolved.isNotEmpty()) {
            return resolved
        }
        return listOfNotNull(localeByTag[englishLocaleTag()])
    }

    fun findByLanguage(language: String): KeyboardLocaleSpec? {
        return allLocales.firstOrNull { spec ->
            spec.localeTag.startsWith(language)
        }
    }

    fun buildLayout(
        locale: KeyboardLocaleSpec,
        state: LayoutState
    ): List<List<KeyboardKey>> {
        return when {
            state.isEmojiVisible -> buildEmojiLayout(locale, state)
            state.isSymbolMode -> buildSymbolLayout(locale, state)
            else -> buildAlphabetLayout(locale, state)
        }
    }

    private fun buildAlphabetLayout(
        locale: KeyboardLocaleSpec,
        state: LayoutState
    ): List<List<KeyboardKey>> {
        val rows = mutableListOf<List<KeyboardKey>>()
        locale.alphaRows.forEachIndexed { index, rowChars ->
            val rowKeys = rowChars.map { char ->
                val value = applyShift(locale, char, state.isShifted)
                KeyboardKey(
                    label = value,
                    value = value,
                    type = KeyType.CHARACTER
                )
            }.toMutableList()

            when (index) {
                0, 1 -> rows.add(rowKeys)
                2 -> {
                    val shiftKey = KeyboardKey(
                        label = "⇧",
                        value = "",
                        type = KeyType.SHIFT,
                        weight = 1.5f,
                        isActive = state.isShifted
                    )
                    val deleteKey = KeyboardKey(
                        label = "⌫",
                        value = "",
                        type = KeyType.DELETE,
                        weight = 1.5f
                    )
                    val middle = rowKeys
                    rows.add(listOf(shiftKey) + middle + listOf(deleteKey))
                }
            }
        }

        rows.add(bottomRow(locale, state))
        return rows
    }

    private fun buildEmojiLayout(
        locale: KeyboardLocaleSpec,
        state: LayoutState
    ): List<List<KeyboardKey>> {
        val rows = mutableListOf<List<KeyboardKey>>()
        val chunks = EmojiProvider.defaultEmojis.chunked(8)

        chunks.take(3).forEachIndexed { index, chunk ->
            val entries = if (index == 2 && chunk.size > 7) chunk.take(7) else chunk
            val rowKeys = entries.map { emoji ->
                KeyboardKey(
                    label = emoji,
                    value = emoji,
                    type = KeyType.CHARACTER
                )
            }.toMutableList()

            if (index == 2) {
                rowKeys.add(
                    KeyboardKey(
                        label = "⌫",
                        value = "",
                        type = KeyType.DELETE,
                        weight = 1.5f
                    )
                )
            }
            rows.add(rowKeys)
        }

        rows.add(bottomRow(locale, state))
        return rows
    }

    private fun buildSymbolLayout(
        locale: KeyboardLocaleSpec,
        state: LayoutState
    ): List<List<KeyboardKey>> {
        val rows = mutableListOf<List<KeyboardKey>>()

        symbolRows.forEachIndexed { index, rowChars ->
            val rowKeys = rowChars.map { char ->
                KeyboardKey(
                    label = char,
                    value = char,
                    type = KeyType.CHARACTER
                )
            }.toMutableList()

            when (index) {
                0, 1 -> rows.add(rowKeys)
                2 -> {
                    val shiftKey = KeyboardKey(
                        label = "⇧",
                        value = "",
                        type = KeyType.SHIFT,
                        weight = 1.5f
                    )
                    val deleteKey = KeyboardKey(
                        label = "⌫",
                        value = "",
                        type = KeyType.DELETE,
                        weight = 1.5f
                    )
                    rows.add(listOf(shiftKey) + rowKeys + listOf(deleteKey))
                }
            }
        }

        rows.add(bottomRow(locale, state))
        return rows
    }

    private fun bottomRow(
        locale: KeyboardLocaleSpec,
        state: LayoutState
    ): List<KeyboardKey> {
        val symbolLabel = if (state.isSymbolMode || state.isEmojiVisible) "ABC" else "?123"
        val symbolKey = KeyboardKey(
            label = symbolLabel,
            value = "",
            type = KeyType.SYMBOL_TOGGLE,
            weight = 1.5f,
            isActive = state.isSymbolMode
        )
        val emojiLabel = if (state.isEmojiVisible) "ABC" else "\uD83D\uDE03"
        val emojiKey = KeyboardKey(
            label = emojiLabel,
            value = "",
            type = KeyType.EMOJI_TOGGLE,
            weight = 1.2f,
            isActive = state.isEmojiVisible
        )
        val languageKey = KeyboardKey(
            label = locale.displayLabel,
            value = "",
            type = KeyType.LANGUAGE,
            weight = 1.2f
        )
        val spaceKey = KeyboardKey(
            label = locale.spaceLabel,
            value = " ",
            type = KeyType.SPACE,
            weight = 3.5f
        )
        val enterKey = KeyboardKey(
            label = locale.enterLabel,
            value = "\n",
            type = KeyType.ENTER,
            weight = 1.8f
        )

        return listOf(symbolKey, emojiKey, languageKey, spaceKey, enterKey)
    }

    private fun applyShift(locale: KeyboardLocaleSpec, value: String, isShifted: Boolean): String {
        if (!isShifted) return value

        return when (locale.localeTag) {
            "ko_KR" -> koreanShiftMap[value] ?: value
            "ja_JP" -> convertHiraganaToKatakana(value)
            else -> {
                val tag = locale.localeTag.replace('_', '-')
                value.uppercase(Locale.forLanguageTag(tag))
            }
        }
    }

    private fun convertHiraganaToKatakana(value: String): String {
        if (value.length != 1) return value
        val code = value[0].code
        return if (code in 0x3041..0x3096) {
            String(Character.toChars(code + 0x60))
        } else {
            value
        }
    }

    private val koreanShiftMap = mapOf(
        "ㅂ" to "ㅃ",
        "ㅈ" to "ㅉ",
        "ㄷ" to "ㄸ",
        "ㄱ" to "ㄲ",
        "ㅅ" to "ㅆ",
        "ㅐ" to "ㅒ",
        "ㅔ" to "ㅖ"
    )
}
