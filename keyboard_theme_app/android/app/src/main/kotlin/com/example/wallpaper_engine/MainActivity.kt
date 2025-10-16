package com.example.wallpaper_engine

import android.content.Context
import android.content.res.Configuration
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

    private val KEYBOARD_THEME_CHANNEL = "com.example.keyboard_theme_engine/theme"
    private val RESOURCE_CHANNEL = "com.snwlee.keyboardtheme/resources"
    private val PREF_NAME = "keyboard_theme_preferences"
    private val CURRENT_THEME_PATH_KEY = "current_theme_path"
    private val CURRENT_THEME_ASSET_KEY = "current_theme_asset"
    private val CURRENT_THEME_MODE_KEY = "current_theme_mode"

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
                                val themeFile = File(filesDir, "keyboard_theme.png")
                                FileOutputStream(themeFile).use { stream ->
                                    stream.write(themeBytes)
                                    stream.flush()
                                }

                                val prefs = getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE)
                                prefs.edit()
                                    .putString(CURRENT_THEME_PATH_KEY, themeFile.absolutePath)
                                    .putString(CURRENT_THEME_ASSET_KEY, assetPath)
                                    .putString(CURRENT_THEME_MODE_KEY, mode)
                                    .apply()

                                withContext(Dispatchers.Main) {
                                    result.success(themeFile.absolutePath)
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
}
