package com.example.wallpaper_engine

import android.app.ActivityNotFoundException
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.res.Configuration
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
    }

    override fun getRenderMode(): RenderMode {
        return RenderMode.surface
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, KEYBOARD_THEME_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
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
                                val normalizedMode = mode.lowercase()
                                val prefs = getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
                                val lightFile = File(filesDir, "keyboard_theme_light.png")
                                val darkFile = File(filesDir, "keyboard_theme_dark.png")
                                val legacyFile = File(filesDir, "keyboard_theme.png")

                                fun writeTheme(target: File): String {
                                    FileOutputStream(target).use { stream ->
                                        stream.write(themeBytes)
                                        stream.flush()
                                    }
                                    return target.absolutePath
                                }

                                val editor = prefs.edit()
                                var primaryPath: String? = null

                                when (normalizedMode) {
                                    "light" -> {
                                        primaryPath = writeTheme(lightFile)
                                        editor.putString(CURRENT_LIGHT_THEME_PATH_KEY, primaryPath)
                                        editor.putString(CURRENT_LIGHT_THEME_ASSET_KEY, assetPath)
                                    }
                                    "dark" -> {
                                        primaryPath = writeTheme(darkFile)
                                        editor.putString(CURRENT_DARK_THEME_PATH_KEY, primaryPath)
                                        editor.putString(CURRENT_DARK_THEME_ASSET_KEY, assetPath)
                                    }
                                    "both" -> {
                                        val lightPath = writeTheme(lightFile)
                                        val darkPath = writeTheme(darkFile)
                                        primaryPath = lightPath
                                        editor.putString(CURRENT_LIGHT_THEME_PATH_KEY, lightPath)
                                        editor.putString(CURRENT_LIGHT_THEME_ASSET_KEY, assetPath)
                                        editor.putString(CURRENT_DARK_THEME_PATH_KEY, darkPath)
                                        editor.putString(CURRENT_DARK_THEME_ASSET_KEY, assetPath)
                                    }
                                    else -> {
                                        val lightPath = writeTheme(lightFile)
                                        val darkPath = writeTheme(darkFile)
                                        primaryPath = lightPath
                                        editor.putString(CURRENT_LIGHT_THEME_PATH_KEY, lightPath)
                                        editor.putString(CURRENT_LIGHT_THEME_ASSET_KEY, assetPath)
                                        editor.putString(CURRENT_DARK_THEME_PATH_KEY, darkPath)
                                        editor.putString(CURRENT_DARK_THEME_ASSET_KEY, assetPath)
                                    }
                                }

                                // Always keep legacy path for backwards compatibility
                                primaryPath = primaryPath ?: writeTheme(legacyFile)
                                editor.putString(CURRENT_THEME_PATH_KEY, primaryPath)
                                editor.putString(CURRENT_THEME_ASSET_KEY, assetPath)
                                editor.putString(
                                    CURRENT_THEME_MODE_KEY,
                                    when (normalizedMode) {
                                        "light", "dark", "both" -> normalizedMode
                                        else -> "both"
                                    }
                                )
                                editor.apply()

                                withContext(Dispatchers.Main) {
                                    result.success(primaryPath)
                                }

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
