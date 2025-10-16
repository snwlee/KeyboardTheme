package com.example.wallpaper_engine

import android.app.WallpaperManager
import android.content.ComponentName
import android.content.Intent
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.os.Build
import android.view.WindowManager
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.android.RenderMode
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.BufferedReader
import java.io.ByteArrayOutputStream
import java.io.IOException
import java.io.InputStreamReader
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeout
import kotlinx.coroutines.TimeoutCancellationException
import android.content.res.Configuration

class MainActivity: FlutterActivity() {

    // Use FlutterSurfaceView for better surface recreation stability on Mali GPUs
    override fun getRenderMode(): RenderMode {
        return RenderMode.surface
    }
    private val WALLPAPER_CHANNEL = "com.example.wallpaper_engine/wallpaper"
    private val RESOURCE_CHANNEL = "com.snwlee.wallpaperengine/resources"

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // Wallpaper setting channel
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, WALLPAPER_CHANNEL).setMethodCallHandler {
            call, result ->
            when (call.method) {
                "setWallpaper" -> {
                    // Check if activity is still valid before processing
                    if (isFinishing || isDestroyed) {
                        result.error("ACTIVITY_DESTROYED", "Activity is no longer valid", null)
                        return@setMethodCallHandler
                    }

                    val imageBytes = call.argument<ByteArray>("imageBytes")
                    val wallpaperType = call.argument<Int>("wallpaperType") ?: 1

                    if (imageBytes == null) {
                        result.error("INVALID_ARGUMENT", "Image bytes are null", null)
                        return@setMethodCallHandler
                    }

                    try {
                        CoroutineScope(Dispatchers.IO).launch {
                            try {
                                // Get screen dimensions for optimal downsampling
                                val displayMetrics = resources.displayMetrics
                                val screenWidth = displayMetrics.widthPixels
                                val screenHeight = displayMetrics.heightPixels

                                // Use moderate dimension for wallpaper (1.8x for better memory efficiency)
                                val reqWidth = (screenWidth * 1.8).toInt()
                                val reqHeight = (screenHeight * 1.8).toInt()

                                // Decode bitmap with optimal sample size
                                val bitmap = decodeSampledBitmapFromBytes(imageBytes, reqWidth, reqHeight)

                                if (bitmap == null) {
                                    withContext(Dispatchers.Main) {
                                        result.error("DECODE_ERROR", "Failed to decode image", null)
                                    }
                                    return@launch
                                }

                                // Set wallpaper with timeout to prevent ANR
                                setWallpaperWithTimeout(bitmap, wallpaperType, result, 8000L) // 8 second timeout
                            } catch (e: Exception) {
                                withContext(Dispatchers.Main) {
                                    result.error("ERROR", "Failed to process image: ${e.message}", e.toString())
                                }
                            }
                        }
                    } catch (e: Exception) {
                        result.error("ERROR", "Failed to launch coroutine: ${e.message}", e.toString())
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }

        // New channel for loading flavor-specific resources
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, RESOURCE_CHANNEL).setMethodCallHandler {
            call, result ->
            if (call.method == "getFlavorConfig") {
                try {
                    val resourceId = resources.getIdentifier("config", "raw", packageName)
                    if (resourceId == 0) {
                        result.error("RESOURCE_NOT_FOUND", "config.json not found in raw resources.", null)
                        return@setMethodCallHandler
                    }
                    val inputStream = resources.openRawResource(resourceId)
                    val reader = BufferedReader(InputStreamReader(inputStream))
                    val jsonString = reader.readText()
                    reader.close()
                    result.success(jsonString)
                } catch (e: Exception) {
                    result.error("READ_ERROR", "Failed to read config.json: ${e.message}", e.toString())
                }
            } else if (call.method == "getAppName") {
                try {
                    val appName = context.getString(R.string.app_name)
                    result.success(appName)
                } catch (e: Exception) {
                    result.error("READ_ERROR", "Failed to read app_name resource: ${e.message}", e.toString())
                }
            } else {
                result.notImplemented()
            }
        }
    }

    override fun onConfigurationChanged(newConfig: Configuration) {
        super.onConfigurationChanged(newConfig)

        // On Android 12+, wallpaper changes trigger Material You dynamic color updates
        // This causes uiMode configuration changes which can freeze the UI
        // Log this event but don't trigger any UI recreation
        val uiModeChanged = (newConfig.uiMode and Configuration.UI_MODE_NIGHT_MASK) !=
                            (resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK)

        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S && uiModeChanged) {
            // Android 12+ Material You theme change detected
            // FlutterActivity already handles this gracefully via configChanges
            android.util.Log.d("MainActivity", "Material You theme update detected - handled by configChanges")
        }
    }

    // Calculate inSampleSize for downsampling bitmap
    private fun calculateInSampleSize(options: BitmapFactory.Options, reqWidth: Int, reqHeight: Int): Int {
        val height = options.outHeight
        val width = options.outWidth
        var inSampleSize = 1

        if (height > reqHeight || width > reqWidth) {
            val halfHeight = height / 2
            val halfWidth = width / 2

            // Calculate the largest inSampleSize value that is a power of 2 and keeps both
            // height and width larger than the requested height and width
            while ((halfHeight / inSampleSize) >= reqHeight && (halfWidth / inSampleSize) >= reqWidth) {
                inSampleSize *= 2
            }
        }

        return inSampleSize
    }

    // Decode and optimize bitmap for wallpaper setting
    private fun decodeSampledBitmapFromBytes(imageBytes: ByteArray, reqWidth: Int, reqHeight: Int): Bitmap? {
        // First decode with inJustDecodeBounds=true to check dimensions
        return BitmapFactory.Options().run {
            inJustDecodeBounds = true
            BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size, this)

            // Calculate inSampleSize
            inSampleSize = calculateInSampleSize(this, reqWidth, reqHeight)

            // Decode bitmap with inSampleSize set
            inJustDecodeBounds = false
            inPreferredConfig = Bitmap.Config.RGB_565 // Use RGB_565 to reduce memory by 50%
            BitmapFactory.decodeByteArray(imageBytes, 0, imageBytes.size, this)
        }
    }

    // Set wallpaper with timeout to prevent ANR
    private suspend fun setWallpaperWithTimeout(bitmap: Bitmap, wallpaperType: Int, result: MethodChannel.Result, timeoutMs: Long) {
        try {
            withTimeout(timeoutMs) {
                setWallpaper(bitmap, wallpaperType, result)
            }
        } catch (e: TimeoutCancellationException) {
            bitmap.recycle()
            withContext(Dispatchers.Main) {
                result.error("TIMEOUT", "Wallpaper setting timed out after ${timeoutMs}ms", null)
            }
        }
    }

    private suspend fun setWallpaper(bitmap: Bitmap, wallpaperType: Int, result: MethodChannel.Result) {
        // Perform heavy operations on IO thread to prevent UI blocking
        withContext(Dispatchers.IO) {
            val wallpaperManager = WallpaperManager.getInstance(applicationContext)
            var optimizedBitmap: Bitmap? = null

            try {
                // Compress bitmap to reduce memory usage (82% quality - balanced)
                val stream = ByteArrayOutputStream()
                bitmap.compress(Bitmap.CompressFormat.JPEG, 82, stream)
                val compressedBytes = stream.toByteArray()
                stream.close()

                // Decode compressed bitmap
                optimizedBitmap = BitmapFactory.decodeByteArray(compressedBytes, 0, compressedBytes.size)

                // Recycle original bitmap to free memory
                bitmap.recycle()

                if (optimizedBitmap == null) {
                    withContext(Dispatchers.Main) {
                        result.error("OPTIMIZATION_ERROR", "Failed to optimize bitmap", null)
                    }
                    return@withContext
                }

                // Set wallpaper (safe to call from background thread)
                // On Android N and above, use flags to specify wallpaper type.
                // CRITICAL FIX for Android 12+: Setting FLAG_SYSTEM | FLAG_LOCK together
                // triggers Material You theme reload twice. Set them sequentially instead.
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
                    when (wallpaperType) {
                        1 -> {
                            // 홈 화면만
                            wallpaperManager.setBitmap(optimizedBitmap, null, true, WallpaperManager.FLAG_SYSTEM)
                        }
                        2 -> {
                            // 잠금 화면만
                            wallpaperManager.setBitmap(optimizedBitmap, null, true, WallpaperManager.FLAG_LOCK)
                        }
                        3 -> {
                            // 둘 다 - Android 12+ Material You 테마 재로드 최소화를 위해 순차 설정
                            // FLAG_SYSTEM 먼저 설정
                            wallpaperManager.setBitmap(optimizedBitmap, null, true, WallpaperManager.FLAG_SYSTEM)
                            // 짧은 지연 후 FLAG_LOCK 설정 (시스템이 안정화되도록)
                            kotlinx.coroutines.delay(100)
                            wallpaperManager.setBitmap(optimizedBitmap, null, true, WallpaperManager.FLAG_LOCK)
                        }
                        else -> {
                            wallpaperManager.setBitmap(optimizedBitmap, null, true, WallpaperManager.FLAG_SYSTEM)
                        }
                    }
                } else {
                    wallpaperManager.setBitmap(optimizedBitmap)
                }

                // Recycle optimized bitmap after setting
                optimizedBitmap.recycle()

                // CRITICAL FIX: Switch to Main thread and delay THERE
                // This ensures Material You theme update (Main thread work) completes
                // BEFORE returning control to Flutter, preventing 216-frame skip
                withContext(Dispatchers.Main) {
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                        // Delay on Main thread to allow UI stabilization
                        // Material You theme recreation happens on Main thread
                        kotlinx.coroutines.delay(300) // 300ms for Activity recreation
                    }
                    result.success(true)
                }
            } catch (e: IOException) {
                optimizedBitmap?.recycle()
                withContext(Dispatchers.Main) {
                    result.error("IO_EXCEPTION", "Failed to set wallpaper.", e.toString())
                }
            } catch (e: Exception) {
                optimizedBitmap?.recycle()
                withContext(Dispatchers.Main) {
                    result.error("ERROR", "Failed to set wallpaper: ${e.message}", e.toString())
                }
            }
        }
    }

    // FlutterActivity handles engine lifecycle automatically
    override fun onDestroy() {
        super.onDestroy()
        // No manual cleanup needed - FlutterActivity handles this
    }
}
