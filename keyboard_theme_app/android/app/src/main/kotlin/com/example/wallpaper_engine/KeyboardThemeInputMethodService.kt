package com.example.wallpaper_engine

import android.graphics.BitmapFactory
import android.graphics.Color
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.view.inputmethod.EditorInfo
import android.view.inputmethod.InputConnection
import android.inputmethodservice.InputMethodService
import android.widget.ImageView
import androidx.core.content.ContextCompat
import androidx.core.view.ViewCompat
import androidx.core.view.WindowInsetsCompat
import androidx.core.view.updateLayoutParams
import androidx.emoji2.text.EmojiCompat
import androidx.emoji2.bundled.BundledEmojiCompatConfig
import com.example.wallpaper_engine.ui.KeyboardKey
import com.example.wallpaper_engine.ui.KeyboardLayouts
import com.example.wallpaper_engine.ui.ModernKeyboardView
import com.example.wallpaper_engine.ui.KeyType
import com.example.wallpaper_engine.ui.KeyboardLocaleSpec
import com.example.wallpaper_engine.ui.LayoutState
import kotlin.math.max

class KeyboardThemeInputMethodService : InputMethodService() {

    private var keyboardView: ModernKeyboardView? = null
    private var keyboardContainer: View? = null
    private var backgroundImageView: ImageView? = null
    private var bottomInsetView: View? = null
    private var availableLocales: List<KeyboardLocaleSpec> = emptyList()

    private val prefs by lazy {
        getSharedPreferences(MainActivity.PREF_NAME, Context.MODE_PRIVATE)
    }

    private var currentLocaleIndex = 0
    private var isShifted = false
    private var isSymbolMode = false
    private var isEmojiVisible = false
    private var hangulComposer: HangulComposer? = null

    override fun onCreate() {
        super.onCreate()
        if (!EmojiCompat.isConfigured()) {
            EmojiCompat.init(BundledEmojiCompatConfig(this))
        }
        loadActiveLocales()
    }

    override fun onCreateInputView(): View {
        val root = LayoutInflater.from(this).inflate(R.layout.view_keyboard, null)
        keyboardView = root.findViewById(R.id.keyboard_view)
        keyboardContainer = root.findViewById(R.id.keyboard_container)
        backgroundImageView = root.findViewById(R.id.keyboard_background_image)
        bottomInsetView = root.findViewById(R.id.keyboard_bottom_inset)
        keyboardView?.apply {
            setOnKeyPressListener(::handleKeyPress)
        }

        setupBottomInsetHandling(root)

        root.post {
            selectLocale(currentLocaleIndex, persist = false)
            refreshKeyboard()
            applyThemeBackground()
        }
        return root
    }

    override fun onStartInputView(attribute: EditorInfo?, restarting: Boolean) {
        super.onStartInputView(attribute, restarting)
        loadActiveLocales()
        hangulComposer?.reset(null)
        isEmojiVisible = false
        refreshKeyboard()
        keyboardView?.post { applyThemeBackground() }
    }

    private fun loadActiveLocales() {
        val prefs = getSharedPreferences(MainActivity.PREF_NAME, Context.MODE_PRIVATE)
        val selectedTags = KeyboardLocaleManager.getSelectedLocales(prefs)
        val resolved = KeyboardLayouts.resolveLocales(selectedTags)
        availableLocales = if (resolved.isEmpty()) {
            val defaults = KeyboardLocaleManager.determineDefaultLocales()
            KeyboardLocaleManager.saveSelectedLocales(prefs, defaults)
            KeyboardLayouts.resolveLocales(defaults)
        } else {
            resolved
        }

        if (availableLocales.isEmpty()) {
            availableLocales = listOf(KeyboardLayouts.allLocales.first())
        }

        val savedTag = prefs.getString(
            MainActivity.CURRENT_LANGUAGE_KEY,
            availableLocales.first().localeTag
        )
        val savedIndex = availableLocales.indexOfFirst { it.localeTag == savedTag }
        currentLocaleIndex = if (savedIndex >= 0) savedIndex else 0

        hangulComposer = if (currentLocale().usesHangulComposer) HangulComposer() else null
    }

    private fun setupBottomInsetHandling(root: View) {
        val insetView = bottomInsetView ?: return
        val minBottomPadding = resources.getDimensionPixelSize(R.dimen.keyboard_bottom_min_padding)
        insetView.updateLayoutParams<ViewGroup.LayoutParams> {
            height = minBottomPadding
        }

        ViewCompat.setOnApplyWindowInsetsListener(root) { _, windowInsets ->
            val systemInsets = windowInsets.getInsets(
                WindowInsetsCompat.Type.systemBars() or WindowInsetsCompat.Type.displayCutout()
            )
            val targetHeight = max(systemInsets.bottom, minBottomPadding)
            insetView.updateLayoutParams<ViewGroup.LayoutParams> {
                if (height != targetHeight) {
                    height = targetHeight
                }
            }
            windowInsets
        }
        ViewCompat.requestApplyInsets(root)
    }

    private fun handleKeyPress(key: KeyboardKey) {
        val ic = currentInputConnection ?: return

        when (key.type) {
            KeyType.CHARACTER -> handleCharacterKey(key, ic)
            KeyType.SPACE -> {
                hangulComposer?.commitPending(ic)
                ic.commitText(" ", 1)
            }
            KeyType.DELETE -> handleDelete(ic)
            KeyType.ENTER -> {
                hangulComposer?.commitPending(ic)
                commitEnter(ic, key.value)
            }
            KeyType.SHIFT -> toggleShift()
            KeyType.SYMBOL_TOGGLE -> {
                hangulComposer?.commitPending(ic)
                if (isEmojiVisible) {
                    isEmojiVisible = false
                    isShifted = false
                    refreshKeyboard()
                } else {
                    toggleSymbolMode()
                }
            }
            KeyType.LANGUAGE -> {
                hangulComposer?.commitPending(ic)
                switchLocale()
            }
            KeyType.EMOJI_TOGGLE -> toggleEmojiMode()
        }
    }

    private fun commitEnter(ic: InputConnection, value: String) {
        if (value == "\n") {
            ic.commitText(value, 1)
        } else {
            ic.commitText("\n", 1)
        }
    }

    private fun handleCharacterKey(key: KeyboardKey, ic: InputConnection) {
        if (isEmojiVisible) {
            ic.commitText(key.value, 1)
            return
        }

        val locale = currentLocale()
        if (!isSymbolMode && locale.usesHangulComposer) {
            val composer = hangulComposer ?: HangulComposer().also { hangulComposer = it }
            val codePoint = key.value.codePointAt(0)
            if (composer.process(codePoint, ic)) {
                return
            }
        }

        ic.commitText(key.value, 1)
        if (!isSymbolMode && isShifted) {
            isShifted = false
            refreshKeyboard()
        }
    }

    private fun handleDelete(ic: InputConnection) {
        if (isEmojiVisible) {
            ic.deleteSurroundingText(1, 0)
            return
        }
        val composer = hangulComposer
        if (!isSymbolMode && composer != null && composer.handleBackspace(ic)) {
            return
        }
        ic.deleteSurroundingText(1, 0)
    }

    private fun toggleShift() {
        if (isSymbolMode) {
            // future: secondary symbol page
            return
        }
        isShifted = !isShifted
        refreshKeyboard()
    }

    private fun toggleSymbolMode() {
        isSymbolMode = !isSymbolMode
        if (!isSymbolMode) {
            hangulComposer?.reset(null)
        }
        if (isSymbolMode) {
            isShifted = false
            isEmojiVisible = false
        }
        refreshKeyboard()
    }

    private fun toggleEmojiMode() {
        isEmojiVisible = !isEmojiVisible
        if (isEmojiVisible) {
            isSymbolMode = false
            isShifted = false
            currentInputConnection?.let { ic -> hangulComposer?.commitPending(ic) }
        } else {
            hangulComposer?.reset(null)
        }
        refreshKeyboard()
    }

    private fun switchLocale() {
        if (availableLocales.isEmpty()) return
        if (availableLocales.size == 1) return
        currentLocaleIndex = (currentLocaleIndex + 1) % availableLocales.size
        selectLocale(currentLocaleIndex, persist = true)
        isSymbolMode = false
        isShifted = false
        isEmojiVisible = false
        refreshKeyboard()
    }

    private fun selectLocale(index: Int, persist: Boolean) {
        if (availableLocales.isEmpty()) {
            availableLocales = KeyboardLayouts.resolveLocales(KeyboardLocaleManager.determineDefaultLocales())
        }
        if (availableLocales.isEmpty()) return
        currentLocaleIndex = index % availableLocales.size
        val locale = currentLocale()
        hangulComposer = if (locale.usesHangulComposer) HangulComposer() else null
        isEmojiVisible = false
        if (persist) {
            prefs.edit()
                .putString(MainActivity.CURRENT_LANGUAGE_KEY, locale.localeTag)
                .apply()
        }
    }

    private fun refreshKeyboard() {
        if (availableLocales.isEmpty()) {
            loadActiveLocales()
        }
        val locale = currentLocale()
        val state = LayoutState(
            isShifted = isShifted,
            isSymbolMode = isSymbolMode,
            isEmojiVisible = isEmojiVisible
        )
        keyboardView?.setKeyboardRows(
            KeyboardLayouts.buildLayout(locale, state)
        )
    }

    private fun currentLocale(): KeyboardLocaleSpec =
        if (availableLocales.isNotEmpty()) availableLocales[currentLocaleIndex] else KeyboardLayouts.allLocales.first()

    private fun applyThemeBackground() {
        val keyboard = keyboardView ?: return
        val container = keyboardContainer ?: return
        val defaultColor = ContextCompat.getColor(this, R.color.keyboard_background_default)

        val lightPath = prefs.getString(MainActivity.CURRENT_LIGHT_THEME_PATH_KEY, null)
        val darkPath = prefs.getString(MainActivity.CURRENT_DARK_THEME_PATH_KEY, null)
        val legacyPath = prefs.getString(MainActivity.CURRENT_THEME_PATH_KEY, null)

        val isNight = (resources.configuration.uiMode and
            android.content.res.Configuration.UI_MODE_NIGHT_MASK) ==
            android.content.res.Configuration.UI_MODE_NIGHT_YES

        val selectedPath = selectThemePath(isNight, lightPath, darkPath, legacyPath)

        bottomInsetView?.setBackgroundColor(defaultColor)

        if (!selectedPath.isNullOrEmpty()) {
            val targetHeight = keyboard.height
            if (targetHeight == 0) {
                keyboard.post { applyThemeBackground() }
                return
            }
            val bitmap = BitmapFactory.decodeFile(selectedPath)
            if (bitmap != null) {
                container.layoutParams = container.layoutParams.apply {
                    height = targetHeight
                }
                backgroundImageView?.setImageBitmap(bitmap)
                container.setBackgroundColor(defaultColor)
                keyboard.setBackgroundColor(Color.TRANSPARENT)
                return
            }
        }

        backgroundImageView?.setImageDrawable(null)
        container.setBackgroundColor(defaultColor)
        keyboard.setBackgroundColor(defaultColor)
    }

    private fun selectThemePath(
        isNight: Boolean,
        lightPath: String?,
        darkPath: String?,
        legacyPath: String?
    ): String? {
        val mode = prefs.getString(MainActivity.CURRENT_THEME_MODE_KEY, "light") ?: "light"
        return when (mode) {
            "dark" -> darkPath ?: lightPath ?: legacyPath
            "both" -> if (isNight) {
                darkPath ?: lightPath ?: legacyPath
            } else {
                lightPath ?: darkPath ?: legacyPath
            }
            else -> lightPath ?: darkPath ?: legacyPath
        }
    }

    private inner class HangulComposer {
        private var initialIdx = -1
        private var medialIdx = -1
        private var finalIdx = -1

        fun reset(ic: InputConnection?) {
            initialIdx = -1
            medialIdx = -1
            finalIdx = -1
            ic?.finishComposingText()
        }

        fun commitPending(ic: InputConnection?) {
            if (!hasComposition() || ic == null) return
            ic.commitText(currentComposition(), 1)
            reset(ic)
        }

        fun process(code: Int, ic: InputConnection): Boolean {
            val consonantIndex = COMPAT_TO_CHO_INDEX[code]
            val vowelIndex = COMPAT_TO_JUNG_INDEX[code]

            if (vowelIndex != null) {
                handleVowel(vowelIndex, ic)
                return true
            }

            if (consonantIndex != null) {
                handleConsonant(code, consonantIndex, ic)
                return true
            }

            return false
        }

        fun handleBackspace(ic: InputConnection): Boolean {
            if (!hasComposition()) return false

            if (finalIdx > 0) {
                finalIdx = FINAL_REDUCTION_MAP[finalIdx] ?: -1
                if (finalIdx >= 0) {
                    ic.setComposingText(currentComposition(), 1)
                } else {
                    ic.setComposingText(currentComposition(), 1)
                }
                if (finalIdx < 0) {
                    finalIdx = -1
                }
                if (!hasComposition()) {
                    ic.finishComposingText()
                }
                return true
            }

            if (medialIdx >= 0) {
                val reduced = MEDIAL_REDUCTION_MAP[medialIdx]
                if (reduced != null) {
                    medialIdx = reduced
                    ic.setComposingText(currentComposition(), 1)
                    return true
                }
                medialIdx = -1
                finalIdx = -1
                if (initialIdx >= 0) {
                    ic.setComposingText(charFromCompat(COMPAT_CHO_LIST[initialIdx]), 1)
                } else {
                    ic.finishComposingText()
                }
                return true
            }

            if (initialIdx >= 0) {
                initialIdx = -1
                ic.finishComposingText()
                return true
            }

            reset(ic)
            return true
        }

        private fun handleVowel(newIndex: Int, ic: InputConnection) {
            if (initialIdx == -1) {
                initialIdx = DEFAULT_INITIAL_INDEX
            }

            if (finalIdx > 0) {
                val split = FINAL_SPLIT_MAP[finalIdx]
                val currentChar = composeHangul(initialIdx, medialIdx, split?.first ?: 0)
                ic.setComposingText(currentChar, 1)
                ic.commitText(currentChar, 1)

                initialIdx = split?.second ?: (FINAL_TO_CHO_INDEX[finalIdx] ?: DEFAULT_INITIAL_INDEX)
                medialIdx = -1
                finalIdx = -1
            }

            if (medialIdx == -1) {
                medialIdx = newIndex
            } else {
                val combined = MEDIAL_COMBINE_MAP[Pair(medialIdx, newIndex)]
                medialIdx = combined ?: run {
                    ic.commitText(currentComposition(), 1)
                    initialIdx = DEFAULT_INITIAL_INDEX
                    newIndex
                }
            }

            finalIdx = -1
            ic.setComposingText(currentComposition(), 1)
        }

        private fun handleConsonant(code: Int, consonantIndex: Int, ic: InputConnection) {
            if (medialIdx < 0) {
                if (initialIdx >= 0) {
                    ic.commitText(charFromCompat(COMPAT_CHO_LIST[initialIdx]), 1)
                }
                initialIdx = consonantIndex
                medialIdx = -1
                finalIdx = -1
                ic.setComposingText(charFromCompat(COMPAT_CHO_LIST[initialIdx]), 1)
                return
            }

            val baseFinalIndex = COMPAT_TO_JONG_INDEX[code]
            if (finalIdx < 0) {
                if (baseFinalIndex != null) {
                    finalIdx = baseFinalIndex
                    ic.setComposingText(currentComposition(), 1)
                    return
                }
            } else {
                val combined = FINAL_COMBINE_MAP[Pair(finalIdx, code)]
                if (combined != null) {
                    finalIdx = combined
                    ic.setComposingText(currentComposition(), 1)
                    return
                }

                ic.commitText(currentComposition(), 1)
                initialIdx = consonantIndex
                medialIdx = -1
                finalIdx = -1
                ic.setComposingText(charFromCompat(COMPAT_CHO_LIST[initialIdx]), 1)
                return
            }

            val newInitial = COMPAT_TO_CHO_INDEX[code]
            if (newInitial != null) {
                ic.commitText(currentComposition(), 1)
                initialIdx = newInitial
                medialIdx = -1
                finalIdx = -1
                ic.setComposingText(charFromCompat(COMPAT_CHO_LIST[initialIdx]), 1)
            }
        }

        private fun hasComposition(): Boolean =
            initialIdx != -1 || medialIdx != -1 || finalIdx != -1

        private fun currentComposition(): String =
            if (initialIdx >= 0 && medialIdx >= 0) {
                composeHangul(initialIdx, medialIdx, finalIdx)
            } else if (initialIdx >= 0) {
                charFromCompat(COMPAT_CHO_LIST[initialIdx])
            } else {
                ""
            }
    }

    private fun composeHangul(initial: Int, medial: Int, finalIdx: Int): String {
        val base = 0xAC00 + (((initial * 21) + medial) * 28) + finalIdx.coerceAtLeast(0)
        return String(Character.toChars(base))
    }

    private fun charFromCompat(code: Int): String =
        String(Character.toChars(code))

    companion object {
        private const val DEFAULT_INITIAL_INDEX = 11 // ㄱ

        private val COMPAT_CHO_LIST = intArrayOf(
            0x3131, 0x3132, 0x3134, 0x3137, 0x3138, 0x3139, 0x3141,
            0x3142, 0x3143, 0x3145, 0x3146, 0x3147, 0x3148, 0x3149,
            0x314A, 0x314B, 0x314C, 0x314D, 0x314E
        )

        private val COMPAT_TO_CHO_INDEX = mapOf(
            0x3131 to 0, 0x3132 to 1, 0x3134 to 2, 0x3137 to 3, 0x3138 to 4,
            0x3139 to 5, 0x3141 to 6, 0x3142 to 7, 0x3143 to 8, 0x3145 to 9,
            0x3146 to 10, 0x3147 to 11, 0x3148 to 12, 0x3149 to 13, 0x314A to 14,
            0x314B to 15, 0x314C to 16, 0x314D to 17, 0x314E to 18
        )

        private val COMPAT_TO_JUNG_INDEX = mapOf(
            0x314F to 0, 0x3150 to 1, 0x3151 to 2, 0x3152 to 3, 0x3153 to 4,
            0x3154 to 5, 0x3155 to 6, 0x3156 to 7, 0x3157 to 8, 0x3158 to 9,
            0x3159 to 10, 0x315A to 11, 0x315B to 12, 0x315C to 13, 0x315D to 14,
            0x315E to 15, 0x315F to 16, 0x3160 to 17, 0x3161 to 18, 0x3162 to 19,
            0x3163 to 20
        )

        private val COMPAT_TO_JONG_INDEX = mapOf(
            0x3131 to 1, 0x3132 to 2, 0x3133 to 3, 0x3134 to 4, 0x3135 to 5,
            0x3136 to 6, 0x3137 to 7, 0x3139 to 8, 0x313A to 9, 0x313B to 10,
            0x313C to 11, 0x313D to 12, 0x313E to 13, 0x313F to 14, 0x3140 to 15,
            0x3141 to 16, 0x3142 to 17, 0x3144 to 18, 0x3145 to 19, 0x3146 to 20,
            0x3147 to 21, 0x3148 to 22, 0x314A to 23, 0x314B to 24, 0x314C to 25,
            0x314D to 26, 0x314E to 27
        )

        private val FINAL_TO_CHO_INDEX = mapOf(
            1 to 0, 2 to 1, 4 to 2, 7 to 3, 8 to 5, 16 to 7, 17 to 7, 19 to 9,
            20 to 10, 21 to 11, 22 to 12, 23 to 14, 24 to 15, 25 to 16, 26 to 17, 27 to 18
        )

        private val MEDIAL_COMBINE_MAP = mapOf(
            Pair(0, 9) to 1,
            Pair(0, 10) to 2,
            Pair(2, 12) to 3,
            Pair(4, 8) to 5,
            Pair(4, 17) to 6,
            Pair(5, 8) to 6,
            Pair(8, 0) to 9,
            Pair(8, 20) to 10,
            Pair(8, 1) to 11,
            Pair(8, 14) to 12,
            Pair(12, 20) to 13,
            Pair(13, 20) to 14,
            Pair(15, 20) to 16
        )

        private val MEDIAL_REDUCTION_MAP = mapOf(
            1 to 0, 2 to 0, 3 to 2, 5 to 4, 6 to 4, 9 to 8, 10 to 8,
            11 to 8, 12 to 8, 13 to 12, 14 to 12, 16 to 15
        )

        private val FINAL_COMBINE_MAP = mapOf(
            Pair(1, 0x3131) to 3,
            Pair(4, 0x3139) to 5,
            Pair(8, 0x3141) to 9,
            Pair(8, 0x3142) to 10,
            Pair(8, 0x3145) to 11,
            Pair(8, 0x3148) to 12,
            Pair(8, 0x3131) to 13,
            Pair(8, 0x3147) to 14,
            Pair(8, 0x314E) to 15,
            Pair(17, 0x3131) to 18,
            Pair(19, 0x3145) to 20,
            Pair(22, 0x3145) to 23,
            Pair(23, 0x3131) to 24,
            Pair(23, 0x3145) to 25,
            Pair(23, 0x3148) to 26,
            Pair(24, 0x3145) to 27
        )

        private val FINAL_SPLIT_MAP = mapOf(
            3 to Pair(1, 0),
            5 to Pair(4, 0x3139),
            9 to Pair(8, 0x3141),
            10 to Pair(8, 0x3142),
            11 to Pair(8, 0x3145),
            12 to Pair(8, 0x3148),
            13 to Pair(8, 0x3131),
            14 to Pair(8, 0x3147),
            15 to Pair(8, 0x314E),
            18 to Pair(17, 0x3131),
            20 to Pair(19, 0x3145),
            23 to Pair(22, 0x3145),
            24 to Pair(23, 0x3131),
            25 to Pair(23, 0x3145),
            26 to Pair(23, 0x3148),
            27 to Pair(24, 0x3145)
        )

        private val FINAL_REDUCTION_MAP = mapOf(
            3 to 1, 5 to 4, 9 to 8, 10 to 8, 11 to 8, 12 to 8, 13 to 8, 14 to 8,
            15 to 8, 18 to 17, 20 to 19, 23 to 22, 24 to 23, 25 to 23, 26 to 23, 27 to 24
        )
    }
}
