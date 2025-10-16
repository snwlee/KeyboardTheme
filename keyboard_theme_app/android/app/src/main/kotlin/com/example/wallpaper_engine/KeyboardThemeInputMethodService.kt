package com.example.wallpaper_engine

import android.content.Context
import android.graphics.BitmapFactory
import android.graphics.drawable.BitmapDrawable
import android.inputmethodservice.InputMethodService
import android.inputmethodservice.Keyboard
import android.inputmethodservice.KeyboardView
import android.text.TextUtils
import android.view.KeyEvent
import android.view.LayoutInflater
import android.view.View
import android.view.inputmethod.EditorInfo
import android.view.inputmethod.InputConnection
import androidx.core.content.ContextCompat

class KeyboardThemeInputMethodService : InputMethodService(), KeyboardView.OnKeyboardActionListener {

    private var keyboardView: KeyboardView? = null
    private var alphaKeyboard: Keyboard? = null
    private var symbolKeyboard: Keyboard? = null

    private var caps: Boolean = false
    private var isSymbols: Boolean = false
    private var currentLocaleIndex: Int = 0
    private var lastEditorInfo: EditorInfo? = null

    private var hangulComposer: HangulComposer? = null

    private val prefs by lazy {
        getSharedPreferences(MainActivity.PREF_NAME, Context.MODE_PRIVATE)
    }

    private val keyboardLocales = listOf(
        KeyboardLocale("en_US", R.xml.keyboard_qwerty_en),
        KeyboardLocale("es_ES", R.xml.keyboard_qwerty_es),
        KeyboardLocale("fr_FR", R.xml.keyboard_qwerty_fr),
        KeyboardLocale("de_DE", R.xml.keyboard_qwerty_de),
        KeyboardLocale("ja_JP", R.xml.keyboard_qwerty_ja),
        KeyboardLocale("ko_KR", R.xml.keyboard_qwerty_ko, composer = ComposerType.HANGUL)
    )

    override fun onCreate() {
        super.onCreate()
        val savedTag = prefs.getString(
            MainActivity.CURRENT_LANGUAGE_KEY,
            keyboardLocales.first().localeTag
        )
        currentLocaleIndex = keyboardLocales.indexOfFirst { it.localeTag == savedTag }
            .takeIf { it >= 0 } ?: 0
    }

    override fun onCreateInputView(): View {
        val view =
            LayoutInflater.from(this).inflate(R.layout.view_keyboard, null) as KeyboardView
        keyboardView = view
        view.isPreviewEnabled = false
        view.setOnKeyboardActionListener(this)
        loadLocale(currentLocaleIndex, persist = false)
        applyThemeBackground()
        return view
    }

    override fun onStartInputView(attribute: EditorInfo?, restarting: Boolean) {
        super.onStartInputView(attribute, restarting)
        lastEditorInfo = attribute
        hangulComposer?.reset(null)
        keyboardView?.keyboard = if (isSymbols) symbolKeyboard else alphaKeyboard
        updateShiftState(attribute)
        applyThemeBackground()
    }

    override fun onFinishInput() {
        super.onFinishInput()
        hangulComposer?.reset(currentInputConnection)
        keyboardView?.closing()
    }

    override fun onPress(primaryCode: Int) = Unit

    override fun onRelease(primaryCode: Int) = Unit

    override fun onKey(primaryCode: Int, keyCodes: IntArray?) {
        val inputConnection = currentInputConnection ?: return
        when (primaryCode) {
            Keyboard.KEYCODE_DELETE -> handleBackspace(inputConnection)
            Keyboard.KEYCODE_SHIFT -> toggleShift()
            Keyboard.KEYCODE_MODE_CHANGE -> toggleSymbols()
            KEYCODE_LANGUAGE_SWITCH -> switchToNextLocale()
            Keyboard.KEYCODE_DONE, KeyEvent.KEYCODE_ENTER -> sendEnter(inputConnection)
            else -> handleCharacter(primaryCode, inputConnection)
        }
    }

    override fun onText(text: CharSequence?) {
        text?.let {
            hangulComposer?.commitPending(currentInputConnection)
            currentInputConnection?.commitText(it, 1)
        }
    }

    override fun swipeLeft() = Unit

    override fun swipeRight() = Unit

    override fun swipeDown() {
        requestHideSelf(0)
    }

    override fun swipeUp() = Unit

    private fun loadLocale(index: Int, persist: Boolean = true) {
        currentLocaleIndex = index
        val descriptor = keyboardLocales[index]

        alphaKeyboard = Keyboard(this, descriptor.alphaLayoutRes)
        symbolKeyboard = Keyboard(this, descriptor.symbolLayoutRes)
        hangulComposer = if (descriptor.composer == ComposerType.HANGUL) {
            HangulComposer()
        } else {
            null
        }

        isSymbols = false
        caps = false
        keyboardView?.keyboard = alphaKeyboard
        keyboardView?.invalidateAllKeys()
        lastEditorInfo?.let { updateShiftState(it) }

        if (persist) {
            prefs.edit()
                .putString(MainActivity.CURRENT_LANGUAGE_KEY, descriptor.localeTag)
                .apply()
        }
    }

    private fun handleBackspace(inputConnection: InputConnection) {
        val composer = hangulComposer
        if (composer != null && composer.handleBackspace(inputConnection)) {
            return
        }

        val selectedText = inputConnection.getSelectedText(0)
        if (!selectedText.isNullOrEmpty()) {
            inputConnection.commitText("", 1)
        } else {
            inputConnection.deleteSurroundingText(1, 0)
        }
    }

    private fun toggleShift() {
        caps = !caps
        val keyboard = keyboardView?.keyboard ?: return
        if (keyboard === alphaKeyboard && hangulComposer == null) {
            alphaKeyboard?.isShifted = caps
            keyboardView?.invalidateAllKeys()
        }
    }

    private fun toggleSymbols() {
        hangulComposer?.commitPending(currentInputConnection)
        isSymbols = !isSymbols
        val newKeyboard = if (isSymbols) symbolKeyboard else alphaKeyboard
        keyboardView?.keyboard = newKeyboard
        if (!isSymbols && hangulComposer == null) {
            alphaKeyboard?.isShifted = caps
        }
        keyboardView?.invalidateAllKeys()
    }

    private fun sendEnter(inputConnection: InputConnection) {
        hangulComposer?.commitPending(inputConnection)
        inputConnection.sendKeyEvent(KeyEvent(KeyEvent.ACTION_DOWN, KeyEvent.KEYCODE_ENTER))
        inputConnection.sendKeyEvent(KeyEvent(KeyEvent.ACTION_UP, KeyEvent.KEYCODE_ENTER))
    }

    private fun handleCharacter(primaryCode: Int, inputConnection: InputConnection) {
        val composer = hangulComposer
        if (composer != null) {
            if (composer.process(primaryCode, inputConnection)) {
                return
            }
        }

        var code = primaryCode
        if (Character.isLetter(code) && caps) {
            code = Character.toUpperCase(code)
        }
        val text = code.toChar().toString()
        hangulComposer?.commitPending(inputConnection)
        inputConnection.commitText(text, 1)
    }

    private fun updateShiftState(attribute: EditorInfo?) {
        caps = attribute?.let {
            val capsMode = it.initialCapsMode
            (capsMode and TextUtils.CAP_MODE_CHARACTERS) != 0 ||
                (capsMode and TextUtils.CAP_MODE_WORDS) != 0 ||
                (capsMode and TextUtils.CAP_MODE_SENTENCES) != 0
        } ?: false

        if (hangulComposer == null) {
            alphaKeyboard?.isShifted = caps
            keyboardView?.invalidateAllKeys()
        }
    }

    private fun switchToNextLocale() {
        hangulComposer?.commitPending(currentInputConnection)
        val nextIndex = (currentLocaleIndex + 1) % keyboardLocales.size
        loadLocale(nextIndex)
        applyThemeBackground()
    }

    private fun applyThemeBackground() {
        val lightPath = prefs.getString(MainActivity.CURRENT_LIGHT_THEME_PATH_KEY, null)
        val darkPath = prefs.getString(MainActivity.CURRENT_DARK_THEME_PATH_KEY, null)
        val legacyPath = prefs.getString(MainActivity.CURRENT_THEME_PATH_KEY, null)

        val uiMode =
            resources.configuration.uiMode and android.content.res.Configuration.UI_MODE_NIGHT_MASK
        val isNight = uiMode == android.content.res.Configuration.UI_MODE_NIGHT_YES

        val hasNewTheme = !lightPath.isNullOrEmpty() || !darkPath.isNullOrEmpty()
        val selectedPath = when {
            isNight && !darkPath.isNullOrEmpty() -> darkPath
            !isNight && !lightPath.isNullOrEmpty() -> lightPath
            !hasNewTheme && !legacyPath.isNullOrEmpty() -> legacyPath
            else -> null
        }

        val view = keyboardView ?: return

        if (!selectedPath.isNullOrEmpty()) {
            val bitmap = BitmapFactory.decodeFile(selectedPath)
            if (bitmap != null) {
                val drawable = BitmapDrawable(resources, bitmap).apply {
                    isFilterBitmap = true
                }
                view.background = drawable
                return
            }
        }

        view.setBackgroundColor(ContextCompat.getColor(this, R.color.keyboard_background_default))
    }

    private fun composeHangul(initial: Int, medial: Int, finalIdx: Int): String {
        val base =
            0xAC00 + (((initial * 21) + medial) * 28) + finalIdx.coerceAtLeast(0)
        return String(Character.toChars(base))
    }

    private fun charFromCompat(code: Int): String =
        String(Character.toChars(code))

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

        fun hasComposition(): Boolean =
            initialIdx != -1 || medialIdx != -1 || finalIdx != -1

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

            ic.commitText(currentComposition(), 1)
            initialIdx = consonantIndex
            medialIdx = -1
            finalIdx = -1
            ic.setComposingText(charFromCompat(COMPAT_CHO_LIST[initialIdx]), 1)
        }

        private fun currentComposition(): String {
            return when {
                medialIdx >= 0 -> composeHangul(
                    initialIdx.takeIf { it >= 0 } ?: DEFAULT_INITIAL_INDEX,
                    medialIdx,
                    finalIdx.coerceAtLeast(0)
                )
                initialIdx >= 0 -> charFromCompat(COMPAT_CHO_LIST[initialIdx])
                else -> ""
            }
        }
    }

    private data class KeyboardLocale(
        val localeTag: String,
        val alphaLayoutRes: Int,
        val symbolLayoutRes: Int = R.xml.keyboard_symbols,
        val composer: ComposerType = ComposerType.NONE
    )

    private enum class ComposerType { NONE, HANGUL }

    companion object {
        private const val KEYCODE_LANGUAGE_SWITCH = -101
        private const val DEFAULT_INITIAL_INDEX = 11 // ㅇ

        private val COMPAT_CHO_LIST = intArrayOf(
            0x3131, 0x3132, 0x3134, 0x3137, 0x3138,
            0x3139, 0x3141, 0x3142, 0x3143, 0x3145,
            0x3146, 0x3147, 0x3148, 0x3149, 0x314A,
            0x314B, 0x314C, 0x314D, 0x314E
        )

        private val COMPAT_TO_CHO_INDEX = mapOf(
            0x3131 to 0, 0x3132 to 1, 0x3134 to 2, 0x3137 to 3,
            0x3139 to 5, 0x3141 to 6, 0x3142 to 7, 0x3145 to 9,
            0x3146 to 10, 0x3147 to 11, 0x3148 to 12, 0x314A to 14,
            0x314B to 15, 0x314C to 16, 0x314D to 17, 0x314E to 18
        )

        private val COMPAT_TO_JUNG_INDEX = mapOf(
            0x314F to 0, 0x3150 to 1, 0x3151 to 2, 0x3152 to 3,
            0x3153 to 4, 0x3154 to 5, 0x3155 to 6, 0x3156 to 7,
            0x3157 to 8, 0x3158 to 9, 0x3159 to 10, 0x315A to 11,
            0x315B to 12, 0x315C to 13, 0x315D to 14, 0x315E to 15,
            0x315F to 16, 0x3160 to 17, 0x3161 to 18, 0x3162 to 19,
            0x3163 to 20
        )

        private val COMPAT_TO_JONG_INDEX = mapOf(
            0x3131 to 1, 0x3132 to 2, 0x3134 to 4, 0x3137 to 7,
            0x3139 to 8, 0x3141 to 16, 0x3142 to 17, 0x3145 to 19,
            0x3146 to 20, 0x3147 to 21, 0x3148 to 22, 0x314A to 23,
            0x314B to 24, 0x314C to 25, 0x314D to 26, 0x314E to 27
        )

        private val FINAL_COMBINE_MAP = mapOf(
            Pair(1, 0x3145) to 3,
            Pair(4, 0x3148) to 5,
            Pair(4, 0x314E) to 6,
            Pair(8, 0x3131) to 9,
            Pair(8, 0x3141) to 10,
            Pair(8, 0x3142) to 11,
            Pair(8, 0x3145) to 12,
            Pair(8, 0x314C) to 13,
            Pair(8, 0x314D) to 14,
            Pair(8, 0x314E) to 15,
            Pair(17, 0x3145) to 18
        )

        private val FINAL_SPLIT_MAP = mapOf(
            3 to Pair(1, 9),
            5 to Pair(4, 12),
            6 to Pair(4, 18),
            9 to Pair(8, 0),
            10 to Pair(8, 6),
            11 to Pair(8, 7),
            12 to Pair(8, 9),
            13 to Pair(8, 16),
            14 to Pair(8, 17),
            15 to Pair(8, 18),
            18 to Pair(17, 9)
        )

        private val FINAL_REDUCTION_MAP = mapOf(
            3 to 1, 5 to 4, 6 to 4, 9 to 8, 10 to 8, 11 to 8, 12 to 8,
            13 to 8, 14 to 8, 15 to 8, 18 to 17
        )

        private val FINAL_TO_CHO_INDEX = mapOf(
            1 to 0, 2 to 1, 4 to 2, 7 to 3, 8 to 5, 16 to 6, 17 to 7,
            19 to 9, 20 to 10, 21 to 11, 22 to 12, 23 to 14, 24 to 15,
            25 to 16, 26 to 17, 27 to 18
        )

        private val MEDIAL_COMBINE_MAP = mapOf(
            Pair(8, 0) to 9,
            Pair(8, 1) to 10,
            Pair(8, 20) to 11,
            Pair(9, 20) to 10,
            Pair(13, 4) to 14,
            Pair(13, 5) to 15,
            Pair(13, 20) to 16,
            Pair(14, 20) to 15,
            Pair(18, 20) to 19
        )

        private val MEDIAL_REDUCTION_MAP = mapOf(
            9 to 8,
            10 to 9,
            11 to 8,
            14 to 13,
            15 to 14,
            16 to 13,
            19 to 18
        )
    }
}
