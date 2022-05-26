package com.producement.yubikit_flutter

import android.content.Context
import android.util.Log
import com.producement.yubikit_flutter.YubikitFlutterPlugin.Companion.SMART_CARD_REQUEST
import com.producement.yubikit_flutter.smartcard.SmartCardAction
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

fun ByteArray.toHex(): String =
    joinToString(separator = "") { eachByte -> "%02x".format(eachByte) }

class YubikitSmartCardMethodCallHandler(
    private val context: Context,
    private val resultHandler: ResultHandler
) :
    MethodChannel.MethodCallHandler, ActivityAware {

    companion object {
        const val TAG = "YKSCMethodCallHandler"
    }

    private lateinit var activity: FlutterActivity

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "sendCommand" -> {
                val arguments = call.arguments<List<Any>>()!!
                val command = arguments[0] as ByteArray
                val application = arguments[1] as ByteArray
                Log.d(
                    TAG,
                    "Sending command: ${command.toHex()} to application ${application.toHex()}"
                )
                val intent = SmartCardAction.smartCardIntent(context, command, application)
                resultHandler.handleResult(result)
                activity.startActivityForResult(intent, SMART_CARD_REQUEST)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        Log.d(TAG, "Attached to activity")
        activity = binding.activity as FlutterActivity
    }

    override fun onDetachedFromActivityForConfigChanges() {
        Log.d(TAG, "Detatching for config changes")
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        Log.d(TAG, "Reattaching from config changes")
        activity = binding.activity as FlutterActivity
    }

    override fun onDetachedFromActivity() {
    }

}