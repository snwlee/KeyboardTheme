package keyboard.keyboardtheme.free.theme.custom.personalkeyboard

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "keyboard_theme/config"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "getConfig" -> {
                        val configId = resources.getIdentifier("config", "raw", packageName)
                        if (configId == 0) {
                            result.error(
                                "config_not_found",
                                "raw/config.json resource is missing for this flavor.",
                                null
                            )
                            return@setMethodCallHandler
                        }
                        runCatching {
                            resources.openRawResource(configId).bufferedReader().use { it.readText() }
                        }.onSuccess { json ->
                            result.success(json)
                        }.onFailure { error ->
                            result.error("config_read_error", error.localizedMessage, null)
                        }
                    }

                    else -> result.notImplemented()
                }
            }
    }
}
