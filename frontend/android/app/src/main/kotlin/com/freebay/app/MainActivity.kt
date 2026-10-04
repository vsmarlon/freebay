package com.freebay.app

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.Executors

class MainActivity : FlutterFragmentActivity() {
    private val imageWorker = Executors.newSingleThreadExecutor()
    private val biometricKey by lazy { NativeBiometricKey(this) }

    override fun onCreate(savedInstanceState: android.os.Bundle?) {
        super.onCreate(savedInstanceState)
        if ((applicationInfo.flags and android.content.pm.ApplicationInfo.FLAG_DEBUGGABLE) == 0) window.setFlags(
            android.view.WindowManager.LayoutParams.FLAG_SECURE,
            android.view.WindowManager.LayoutParams.FLAG_SECURE,
        )
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        biometricKey.register(flutterEngine.dartExecutor.binaryMessenger)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.freebay.app/image_compositor")
            .setMethodCallHandler { call, result ->
                if (call.method != "compose") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val arguments = call.arguments as? Map<*, *>
                if (arguments == null) {
                    result.error("invalid_arguments", "Invalid image composition arguments", null)
                    return@setMethodCallHandler
                }
                imageWorker.execute {
                    try {
                        val png = NativeImageCompositor.compose(arguments, assets)
                        runOnUiThread { result.success(png) }
                    } catch (error: IllegalArgumentException) {
                        runOnUiThread { result.error("invalid_image", error.message, null) }
                    } catch (error: Exception) {
                        runOnUiThread { result.error("composition_failed", "Image composition failed", null) }
                    }
                }
            }
    }

    override fun onDestroy() {
        imageWorker.shutdown()
        super.onDestroy()
    }
}
