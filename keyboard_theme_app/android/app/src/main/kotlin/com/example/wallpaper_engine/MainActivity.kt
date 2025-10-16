package com.example.wallpaper_engine

import android.content.ActivityNotFoundException
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.res.Configuration
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.graphics.Canvas
import android.graphics.Color
import android.graphics.Paint
import android.provider.Settings
import android.view.inputmethod.InputMethodManager
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.RenderMode
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.BufferedReader
import java.io.File
import java.io.FileOutputStream
import java.io.InputStreamReader
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

class MainActivity : FlutterActivity() {

    companion object {
        const val KEYBOARD_THEME_CHANNEL = "com.example.keyboard_theme_engine/theme"
        const val RESOURCE_CHANNEL = "com.snwlee.keyboardtheme/resources"
        const val PREF_NAME = "keyboard_theme_preferences"
        const val CURRENT_THEME_PATH_KEY = "current_theme_path"
        const val CURRENT_THEME_ASSET_KEY = "current_theme_asset"
        const val CURRENT_THEME_MODE_KEY = "current_theme_mode"
        const val CURRENT_LIGHT_THEME_PATH_KEY = "current_light_theme_path"
        const val CURRENT_DARK_THEME_PATH_KEY = "current_dark_theme_path"
        const val CURRENT_LIGHT_THEME_ASSET_KEY = "current_light_theme_asset"
        const val CURRENT_DARK_THEME_ASSET_KEY = "current_dark_theme_asset"
        const val CURRENT_LANGUAGE_KEY = "current_language_tag"
    }

    override fun getRenderMode(): RenderMode {
        return RenderMode.surface
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        KeyboardLocaleManager.ensureSelectionsValid(getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE))

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, KEYBOARD_THEME_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getEnabledLocales" -> {
                        val prefs = getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
                        val locales = KeyboardLocaleManager.getSelectedLocales(prefs)
                        result.success(locales)
                    }
                    "setEnabledLocales" -> {
                        val prefs = getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
                        val locales = call.argument<List<String>>("locales") ?: emptyList()
                        KeyboardLocaleManager.saveSelectedLocales(prefs, locales)
                        result.success(null)
                    }
                    "applyKeyboardTheme" -> {
                        if (isFinishing || isDestroyed) {
                            result.error("ACTIVITY_DESTROYED", "Activity is no longer valid", null)
                            return@setMethodCallHandler
                        }

                        val themeBytes = call.argument<ByteArray>("themeBytes")
                        val assetPath = call.argument<String>("assetPath") ?: "unknown"
                        val mode = call.argument<String>("mode") ?: "default"

                        if (themeBytes == null) {
                            result.error("INVALID_ARGUMENT", "Theme bytes are null", null)
                            return@setMethodCallHandler
                        }

                        CoroutineScope(Dispatchers.IO).launch {
                            try {
                                val normalizedMode = when (mode.lowercase()) {
                                    "dark" -> "dark"
                                    "both" -> "both"
                                    "light" -> "light"
                                    else -> "light"
                                }
                                val prefs = getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
                                val lightFile = File(filesDir, "keyboard_theme_light.png")
                                val darkFile = File(filesDir, "keyboard_theme_dark.png")
                                val legacyFile = File(filesDir, "keyboard_theme.png")

                                val sourceBitmap = BitmapFactory.decodeByteArray(
                                    themeBytes,
                                    0,
                                    themeBytes.size
                                ) ?: throw IllegalArgumentException("Unable to decode theme image")

                                fun saveTheme(target: File, bitmap: Bitmap): String {
                                    FileOutputStream(target).use { stream ->
                                        if (!bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)) {
                                            throw IllegalStateException("Unable to encode theme image")
                                        }
                                        stream.flush()
                                    }
                                    return target.absolutePath
                                }

                                fun createLightVariant(source: Bitmap): Bitmap {
                                    if (source.width == 0 || source.height == 0) {
                                        return source.copy(
                                            source.config ?: Bitmap.Config.ARGB_8888,
                                            true
                                        )
                                    }
                                    val result = Bitmap.createBitmap(
                                        source.width,
                                        source.height,
                                        Bitmap.Config.ARGB_8888
                                    )
                                    val canvas = Canvas(result)
                                    canvas.drawBitmap(source, 0f, 0f, null)
                                    val overlayPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                                        color = Color.argb((0.18f * 255).toInt(), 255, 255, 255)
                                    }
                                    canvas.drawRect(
                                        0f,
                                        0f,
                                        result.width.toFloat(),
                                        result.height.toFloat(),
                                        overlayPaint
                                    )
                                    return result
                                }

                                fun createDarkVariant(source: Bitmap): Bitmap {
                                    if (source.width == 0 || source.height == 0) {
                                        return source.copy(
                                            source.config ?: Bitmap.Config.ARGB_8888,
                                            true
                                        )
                                    }
                                    val result = Bitmap.createBitmap(
                                        source.width,
                                        source.height,
                                        Bitmap.Config.ARGB_8888
                                    )
                                    val canvas = Canvas(result)
                                    canvas.drawBitmap(source, 0f, 0f, null)
                                    val overlayPaint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
                                        color = Color.argb((0.45f * 255).toInt(), 0, 0, 0)
                                    }
                                    canvas.drawRect(
                                        0f,
                                        0f,
                                        result.width.toFloat(),
                                        result.height.toFloat(),
                                        overlayPaint
                                    )
                                    return result
                                }

                                var lightBitmap: Bitmap? = null
                                var darkBitmap: Bitmap? = null
                                fun obtainLightVariant(): Bitmap {
                                    val existing = lightBitmap
                                    if (existing != null) {
                                        return existing
                                    }
                                    val generated = createLightVariant(sourceBitmap)
                                    lightBitmap = generated
                                    return generated
                                }
                                fun obtainDarkVariant(): Bitmap {
                                    val existing = darkBitmap
                                    if (existing != null) {
                                        return existing
                                    }
                                    val generated = createDarkVariant(sourceBitmap)
                                    darkBitmap = generated
                                    return generated
                                }

                                val editor = prefs.edit()
                                var primaryPath: String? = null

                                when (normalizedMode) {
                                    "light" -> {
                                        primaryPath = saveTheme(lightFile, obtainLightVariant())
                                        editor.putString(CURRENT_LIGHT_THEME_PATH_KEY, primaryPath)
                                        editor.putString(CURRENT_LIGHT_THEME_ASSET_KEY, assetPath)
                                    }
                                    "dark" -> {
                                        val darkPath = saveTheme(darkFile, obtainDarkVariant())
                                        primaryPath = darkPath
                                        editor.putString(CURRENT_DARK_THEME_PATH_KEY, darkPath)
                                        editor.putString(CURRENT_DARK_THEME_ASSET_KEY, assetPath)
                                    }
                                    "both" -> {
                                        val lightPath = saveTheme(lightFile, obtainLightVariant())
                                        val darkPath = saveTheme(darkFile, obtainDarkVariant())
                                        primaryPath = lightPath
                                        editor.putString(CURRENT_LIGHT_THEME_PATH_KEY, lightPath)
                                        editor.putString(CURRENT_LIGHT_THEME_ASSET_KEY, assetPath)
                                        editor.putString(CURRENT_DARK_THEME_PATH_KEY, darkPath)
                                        editor.putString(CURRENT_DARK_THEME_ASSET_KEY, assetPath)
                                    }
                                    else -> {
                                        val lightPath = saveTheme(lightFile, obtainLightVariant())
                                        val darkPath = saveTheme(darkFile, obtainDarkVariant())
                                        primaryPath = lightPath
                                        editor.putString(CURRENT_LIGHT_THEME_PATH_KEY, lightPath)
                                        editor.putString(CURRENT_LIGHT_THEME_ASSET_KEY, assetPath)
                                        editor.putString(CURRENT_DARK_THEME_PATH_KEY, darkPath)
                                        editor.putString(CURRENT_DARK_THEME_ASSET_KEY, assetPath)
                                    }
                                }

                                // Always keep legacy path for backwards compatibility
                                if (primaryPath == null) {
                                    primaryPath = saveTheme(legacyFile, sourceBitmap)
                                }
                                editor.putString(CURRENT_THEME_PATH_KEY, primaryPath)
                                editor.putString(CURRENT_THEME_ASSET_KEY, assetPath)
                                editor.putString(
                                    CURRENT_THEME_MODE_KEY,
                                    when (normalizedMode) {
                                        "light", "dark", "both" -> normalizedMode
                                        else -> "light"
                                    }
                                )
                                editor.apply()

                                if (!sourceBitmap.isRecycled) {
                                    sourceBitmap.recycle()
                                }
                                lightBitmap?.let { bitmap ->
                                    if (!bitmap.isRecycled) {
                                        bitmap.recycle()
                                    }
                                }
                                darkBitmap?.let { bitmap ->
                                    if (!bitmap.isRecycled) {
                                        bitmap.recycle()
                                    }
                                }

                                withContext(Dispatchers.Main) {
                                    result.success(primaryPath)
                                }
                            } catch (e: Exception) {
                                withContext(Dispatchers.Main) {
                                    result.error(
                                        "APPLY_ERROR",
                                        "Failed to apply keyboard theme: ${e.message}",
                                        e.toString()
                                    )
                                }
                            }
                        }
                    }
                    "getCurrentKeyboardTheme" -> {
                        val prefs = getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
                        val path = prefs.getString(CURRENT_THEME_PATH_KEY, null)
                        result.success(path)
                    }
                    "showKeyboardPicker" -> {
                        val imm = getInputMethodManager()
                        if (imm != null) {
                            imm.showInputMethodPicker()
                            result.success(null)
                        } else {
                            result.error("IMM_UNAVAILABLE", "InputMethodManager not available", null)
                        }
                    }
                    "openKeyboardSettings" -> {
                        try {
                            val intent = Intent(Settings.ACTION_INPUT_METHOD_SETTINGS).apply {
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(intent)
                            result.success(null)
                        } catch (e: ActivityNotFoundException) {
                            result.error("SETTINGS_UNAVAILABLE", "Unable to open keyboard settings", e.toString())
                        }
                    }
                    "isKeyboardEnabled" -> {
                        result.success(isKeyboardEnabled())
                    }
                    "isKeyboardSelected" -> {
                        result.success(isKeyboardSelected())
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, RESOURCE_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getFlavorConfig" -> {
                        try {
                            val resourceId = resources.getIdentifier("config", "raw", packageName)
                            if (resourceId == 0) {
                                result.error(
                                    "RESOURCE_NOT_FOUND",
                                    "config.json not found in raw resources.",
                                    null
                                )
                                return@setMethodCallHandler
                            }
                            val inputStream = resources.openRawResource(resourceId)
                            val reader = BufferedReader(InputStreamReader(inputStream))
                            val jsonString = reader.readText()
                            reader.close()
                            result.success(jsonString)
                        } catch (e: Exception) {
                            result.error(
                                "READ_ERROR",
                                "Failed to read config.json: ${e.message}",
                                e.toString()
                            )
                        }
                    }
                    "getAppName" -> {
                        try {
                            val appName = getString(R.string.app_name)
                            result.success(appName)
                        } catch (e: Exception) {
                            result.error(
                                "READ_ERROR",
                                "Failed to read app_name resource: ${e.message}",
                                e.toString()
                            )
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    override fun onConfigurationChanged(newConfig: Configuration) {
        super.onConfigurationChanged(newConfig)
    }

    private fun getInputMethodManager(): InputMethodManager? {
        return getSystemService(Context.INPUT_METHOD_SERVICE) as? InputMethodManager
    }

    private fun isKeyboardEnabled(): Boolean {
        val imm = getInputMethodManager() ?: return false
        val componentName = ComponentName(this, KeyboardThemeInputMethodService::class.java)
        val serviceId = componentName.flattenToShortString()
        return imm.enabledInputMethodList.any { it.id == serviceId }
    }

    private fun isKeyboardSelected(): Boolean {
        val componentName = ComponentName(this, KeyboardThemeInputMethodService::class.java)
        val serviceId = componentName.flattenToShortString()
        val current = Settings.Secure.getString(contentResolver, Settings.Secure.DEFAULT_INPUT_METHOD)
        return current == serviceId
    }
}
