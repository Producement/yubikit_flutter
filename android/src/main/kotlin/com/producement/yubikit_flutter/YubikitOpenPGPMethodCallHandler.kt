package com.producement.yubikit_flutter

import android.content.Context
import android.util.Log
import androidx.annotation.NonNull
import com.producement.yubikit_flutter.pgp.GenerateECAsymmetricKeyAction
import com.producement.yubikit_flutter.pgp.GenerateRSAAsymmetricKeyAction
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class YubikitOpenPGPMethodCallHandler(
    private val context: Context,
    private val resultHandler: ResultHandler
) : MethodChannel.MethodCallHandler,
    ActivityAware {

    private lateinit var activity: FlutterActivity
    private lateinit var binding: ActivityPluginBinding

    companion object {
        private const val TAG = "YubikitPGPHandler"

    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: MethodChannel.Result) {
        Log.d(TAG, "Method ${call.method} called")
        when (call.method) {
            "generateECAsymmetricKey" -> {
                val arguments = call.arguments<List<Any>>()!!
                val keyAttributesCommands = arguments[0] as List<ByteArray>
                val generateAsymmetricKeyCommands = arguments[1] as List<ByteArray>
                val curveParameters = arguments[2] as List<ByteArray>
                val keySlots = arguments[3] as List<Int>
                val genTimes = arguments[4] as List<Int>
                val verify = arguments[5] as ByteArray
                val intent = GenerateECAsymmetricKeyAction.generateECAsymmetricKeyIntent(
                    context,
                    keyAttributesCommands,
                    generateAsymmetricKeyCommands,
                    curveParameters,
                    keySlots,
                    genTimes,
                    verify
                )
                resultHandler.handleResult(result)
                activity.startActivityForResult(intent, YubikitFlutterPlugin.GENERATE_EC_ASYM_KEY)
            }
            "generateRSAAsymmetricKey" -> {
                val arguments = call.arguments<List<Any>>()!!
                val keyAttributesCommands = arguments[0] as List<ByteArray>
                val generateAsymmetricKeyCommands = arguments[1] as List<ByteArray>
                val keySlots = arguments[2] as List<Int>
                val genTimes = arguments[3] as List<Int>
                val verify = arguments[4] as ByteArray
                val intent = GenerateRSAAsymmetricKeyAction.generateRSAAsymmetricKeyIntent(
                    context,
                    keyAttributesCommands,
                    generateAsymmetricKeyCommands,
                    keySlots,
                    genTimes,
                    verify
                )
                resultHandler.handleResult(result)
                activity.startActivityForResult(intent, YubikitFlutterPlugin.GENERATE_RSA_ASYM_KEY)
            }
        }
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        Log.d(TAG, "Attached to activity")
        activity = binding.activity as FlutterActivity
        this.binding = binding
    }

    override fun onDetachedFromActivityForConfigChanges() {
        Log.d(TAG, "Detached from activity for config changes")
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        Log.d(TAG, "Reattached to activity")
        activity = binding.activity as FlutterActivity
        this.binding = binding
    }

    override fun onDetachedFromActivity() {
        Log.d(TAG, "Detached from activity")
    }
}