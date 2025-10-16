package com.example.wallpaper_engine.ui

import android.content.Context
import android.util.AttributeSet
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.LinearLayout
import androidx.appcompat.widget.AppCompatButton
import androidx.core.content.ContextCompat
import com.example.wallpaper_engine.R

class ModernKeyboardView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
    defStyleAttr: Int = 0
) : LinearLayout(context, attrs, defStyleAttr) {

    private var rows: List<List<KeyboardKey>> = emptyList()
    private var keyPressListener: ((KeyboardKey) -> Unit)? = null

    init {
        orientation = VERTICAL
    }

    fun setKeyboardRows(rows: List<List<KeyboardKey>>) {
        this.rows = rows
        buildKeyboard()
    }

    fun setOnKeyPressListener(listener: (KeyboardKey) -> Unit) {
        keyPressListener = listener
    }

    private fun buildKeyboard() {
        removeAllViews()
        if (rows.isEmpty()) return

        val rowMargin = resources.getDimensionPixelSize(R.dimen.keyboard_row_margin)
        val keyMargin = resources.getDimensionPixelSize(R.dimen.keyboard_key_margin)
        val keyHeight = resources.getDimensionPixelSize(R.dimen.keyboard_key_height)

        rows.forEach { row ->
            val rowLayout = LinearLayout(context).apply {
                orientation = HORIZONTAL
                layoutParams = LayoutParams(
                    LayoutParams.MATCH_PARENT,
                    LayoutParams.WRAP_CONTENT
                ).apply {
                    topMargin = rowMargin
                }
                gravity = Gravity.CENTER
            }

            row.forEach { key ->
                val button = createKeyButton(key, keyMargin, keyHeight)
                rowLayout.addView(button)
            }

            addView(rowLayout)
        }
    }

    private fun createKeyButton(
        key: KeyboardKey,
        margin: Int,
        height: Int
    ): View {
        return AppCompatButton(context).apply {
            text = key.label
            isAllCaps = false
            gravity = Gravity.CENTER
            layoutParams = LinearLayout.LayoutParams(0, height, key.weight).apply {
                setMargins(margin, 0, margin, 0)
            }
            setPadding(0, 0, 0, 0)
            background = ContextCompat.getDrawable(
                context,
                if (key.isActive) R.drawable.keyboard_key_background_active
                else R.drawable.keyboard_key_background
            )
            setTextColor(ContextCompat.getColor(context, android.R.color.white))
            textSize = when (key.type) {
                KeyType.SPACE -> 14f
                KeyType.LANGUAGE, KeyType.SYMBOL_TOGGLE, KeyType.SHIFT -> 14f
                else -> 16f
            }
            setOnClickListener { keyPressListener?.invoke(key) }
        }
    }
}
