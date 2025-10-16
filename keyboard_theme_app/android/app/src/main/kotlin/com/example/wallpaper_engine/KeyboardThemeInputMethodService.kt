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
    private lateinit var qwertyKeyboard: Keyboard
    private lateinit var symbolsKeyboard: Keyboard
    private var caps: Boolean = false
    private var isSymbols: Boolean = false

    override fun onCreate() {
        super.onCreate()
        qwertyKeyboard = Keyboard(this, R.xml.keyboard_qwerty)
        symbolsKeyboard = Keyboard(this, R.xml.keyboard_symbols)
    }

    override fun onCreateInputView(): View {
        val view = LayoutInflater.from(this).inflate(R.layout.view_keyboard, null) as KeyboardView
        keyboardView = view
        view.keyboard = qwertyKeyboard
        view.isPreviewEnabled = false
        view.setOnKeyboardActionListener(this)
        applyThemeBackground()
        return view
    }

    override fun onStartInputView(attribute: EditorInfo?, restarting: Boolean) {
        super.onStartInputView(attribute, restarting)
        keyboardView?.keyboard = if (isSymbols) symbolsKeyboard else qwertyKeyboard
        updateShiftState(attribute)
        applyThemeBackground()
    }

    override fun onFinishInput() {
        super.onFinishInput()
        keyboardView?.closing()
    }

    override fun onPress(primaryCode: Int) {
        // no-op
    }

    override fun onRelease(primaryCode: Int) {
        // no-op
    }

    override fun onKey(primaryCode: Int, keyCodes: IntArray?) {
        val inputConnection = currentInputConnection ?: return
        when (primaryCode) {
            Keyboard.KEYCODE_DELETE -> handleBackspace(inputConnection)
            Keyboard.KEYCODE_SHIFT -> toggleShift()
            Keyboard.KEYCODE_MODE_CHANGE -> toggleSymbols()
            Keyboard.KEYCODE_DONE, 10 -> sendEnter(inputConnection)
            else -> handleCharacter(primaryCode, inputConnection)
        }
    }

    override fun onText(text: CharSequence?) {
        text?.let {
            currentInputConnection?.commitText(it, 1)
        }
    }

    override fun swipeLeft() {
        // no-op
    }

    override fun swipeRight() {
        // no-op
    }

    override fun swipeDown() {
        requestHideSelf(0)
    }

    override fun swipeUp() {
        // no-op
    }

    private fun handleBackspace(inputConnection: InputConnection) {
        val selectedText = inputConnection.getSelectedText(0)
        if (selectedText != null && selectedText.isNotEmpty()) {
            inputConnection.commitText("", 1)
        } else {
            inputConnection.deleteSurroundingText(1, 0)
        }
    }

    private fun toggleShift() {
        caps = !caps
        val keyboard = keyboardView?.keyboard ?: return
        if (keyboard === qwertyKeyboard) {
            qwertyKeyboard.isShifted = caps
            keyboardView?.invalidateAllKeys()
        }
    }

    private fun toggleSymbols() {
        isSymbols = !isSymbols
        val newKeyboard = if (isSymbols) symbolsKeyboard else qwertyKeyboard
        keyboardView?.keyboard = newKeyboard
        if (!isSymbols) {
            qwertyKeyboard.isShifted = caps
        }
        keyboardView?.invalidateAllKeys()
    }

    private fun sendEnter(inputConnection: InputConnection) {
        inputConnection.sendKeyEvent(KeyEvent(KeyEvent.ACTION_DOWN, KeyEvent.KEYCODE_ENTER))
        inputConnection.sendKeyEvent(KeyEvent(KeyEvent.ACTION_UP, KeyEvent.KEYCODE_ENTER))
    }

    private fun handleCharacter(primaryCode: Int, inputConnection: InputConnection) {
        var code = primaryCode
        if (Character.isLetter(code) && caps) {
            code = Character.toUpperCase(code)
        }
        inputConnection.commitText(code.toChar().toString(), 1)
    }

    private fun updateShiftState(attribute: EditorInfo?) {
        caps = attribute?.let {
            val capsMode = it.initialCapsMode
            (capsMode and TextUtils.CAP_MODE_CHARACTERS) != 0 ||
                (capsMode and TextUtils.CAP_MODE_WORDS) != 0 ||
                (capsMode and TextUtils.CAP_MODE_SENTENCES) != 0
        } ?: false
        qwertyKeyboard.isShifted = caps
        keyboardView?.invalidateAllKeys()
    }

    private fun applyThemeBackground() {
        val prefs = getSharedPreferences(MainActivity.PREF_NAME, Context.MODE_PRIVATE)
        val lightPath = prefs.getString(MainActivity.CURRENT_LIGHT_THEME_PATH_KEY, null)
        val darkPath = prefs.getString(MainActivity.CURRENT_DARK_THEME_PATH_KEY, null)
        val legacyPath = prefs.getString(MainActivity.CURRENT_THEME_PATH_KEY, null)

        val uiMode = resources.configuration.uiMode and android.content.res.Configuration.UI_MODE_NIGHT_MASK
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
}
