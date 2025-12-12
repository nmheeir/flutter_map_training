package com.example.flutter_map_training

import android.content.Intent
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channel = "com.example.flutter_map_training/map_live_activity"
    private lateinit var locationTrackingNotificationManager: LocationTrackingNotificationManager
    private var methodChannel: MethodChannel? = null;

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        locationTrackingNotificationManager = LocationTrackingNotificationManager(this)

        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channel).apply {
            setMethodCallHandler { call, result ->
                when (call.method) {
                    "startLiveActivity" -> {
                        val data = call.arguments as? Map<String, Any>
                        locationTrackingNotificationManager.startLiveActivity(data)
                        result.success(null)
                    }

                    "updateLiveActivity" -> {
                        val data = call.arguments as? Map<String, Any>
                        locationTrackingNotificationManager.updateLiveActivity(data)
                        result.success(null)
                    }

                    "endLiveActivity" -> {
                        locationTrackingNotificationManager.endLiveActivity()
                        result.success(null)
                    }

                    else -> {
                        result.notImplemented()
                    }
                }
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        val methodName = intent.getStringExtra("FLUTTER_METHOD")

        if (methodName != null) {
            methodChannel?.invokeMethod(methodName, null)
        }
    }
}
