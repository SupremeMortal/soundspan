package io.soundspan.app

import android.net.Uri
import android.os.Build
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // The Android API level, for permissions that exist from one level
        // on (lib/platform/device_info).
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "io.soundspan.app/device_info")
            .setMethodCallHandler { call, result ->
                if (call.method == "sdkInt") {
                    result.success(Build.VERSION.SDK_INT)
                } else {
                    result.notImplemented()
                }
            }
        // Read access for the car hosts to a pinned cover's content URI
        // (lib/platform/artwork_content_uri).
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "io.soundspan.app/artwork")
            .setMethodCallHandler { call, result ->
                val uri = (call.arguments as? String)?.let(Uri::parse)
                if (call.method == "grant" && uri != null) {
                    ArtworkGrants.grant(applicationContext, uri)
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
    }
}
