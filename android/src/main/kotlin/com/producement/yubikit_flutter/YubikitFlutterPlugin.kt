package com.producement.yubikit_flutter

import android.util.Log
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel


class YubikitFlutterPlugin : FlutterPlugin, ActivityAware {
    private lateinit var pivChannel: MethodChannel
    private lateinit var smartCardChannel: MethodChannel
    private lateinit var smartCardMethodHandler: YubikitSmartCardMethodCallHandler
    private lateinit var pivMethodHandler: YubikitPivMethodCallHandler
    private lateinit var eventChannel: EventChannel

    companion object {
        private const val TAG = "YubikitFlutter"
    }

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        Log.d(TAG, "Attached to engine")
        pivChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "yubikit_flutter_piv")
        pivMethodHandler = YubikitPivMethodCallHandler(flutterPluginBinding.applicationContext)
        pivChannel.setMethodCallHandler(pivMethodHandler)

        smartCardChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "yubikit_flutter_sc")
        smartCardMethodHandler = YubikitSmartCardMethodCallHandler()
        smartCardChannel.setMethodCallHandler(smartCardMethodHandler)

        eventChannel = EventChannel(flutterPluginBinding.binaryMessenger, "yubikit_flutter_status")
        eventChannel.setStreamHandler(smartCardMethodHandler)
    }


    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        Log.d(TAG, "Detached from engine")
        pivChannel.setMethodCallHandler(null)
        smartCardChannel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        Log.d(TAG, "Attached to activity")
        pivMethodHandler.onAttachedToActivity(binding)
        smartCardMethodHandler.onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        Log.d(TAG, "Detached from activity for config changes")
        pivMethodHandler.onDetachedFromActivityForConfigChanges()
        smartCardMethodHandler.onDetachedFromActivityForConfigChanges()
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        Log.d(TAG, "Reattached to activity")
        pivMethodHandler.onReattachedToActivityForConfigChanges(binding)
        smartCardMethodHandler.onReattachedToActivityForConfigChanges(binding)
    }

    override fun onDetachedFromActivity() {
        Log.d(TAG, "Detached from activity")
        smartCardMethodHandler.onDetachedFromActivity()
        pivMethodHandler.onDetachedFromActivity()
    }

}
