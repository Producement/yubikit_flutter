package com.producement.yubikit_flutter

import android.content.Context
import android.content.Intent
import android.util.Log
import androidx.annotation.NonNull
import androidx.lifecycle.MutableLiveData
import com.producement.yubikit_flutter.PivDecryptAction.Companion.pivDecryptIntent
import com.producement.yubikit_flutter.PivSignAction.Companion.pivSignIntent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import java.lang.Exception
import java.lang.RuntimeException

class YubikitFlutterPlugin : FlutterPlugin, MethodCallHandler, ActivityAware,
    PluginRegistry.ActivityResultListener {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private lateinit var activity: FlutterActivity
    private val responseData = MutableLiveData<kotlin.Result<*>>()

    companion object {
        private const val TAG = "YubikitFlutter"
        private const val SIGNATURE_REQUEST = 1
        private const val DECRYPT_REQUEST = 2
    }

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        Log.d(TAG, "Attached to engine")
        context = flutterPluginBinding.applicationContext
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "yubikit_flutter")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        Log.d(TAG, "Method ${call.method} called")
        when (call.method) {
            "pivSignWithKey" -> {
                val arguments = call.arguments<List<Any>>()
                val slot = arguments[0] as Int
                val keyType = arguments[1] as Int
                val algorithm = arguments[2] as String
                val pin = arguments[3] as String
                val message = arguments[4] as ByteArray
                val intent =
                    pivSignIntent(context, pin, algorithm, slot, keyType, message)
                observeResponse(result)
                activity.startActivityForResult(intent, SIGNATURE_REQUEST)
            }
            "pivDecryptWithKey" -> {
                val arguments = call.arguments<Array<Any>>()
                val slot = arguments[0] as Int
                val algorithm = arguments[1] as String
                val pin = arguments[2] as String
                val message = arguments[3] as ByteArray
                val intent = pivDecryptIntent(context, pin, algorithm, slot, message)
                observeResponse(result)
                activity.startActivityForResult(intent, DECRYPT_REQUEST)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun observeResponse(result: Result) {
        responseData.observe(activity) { newValue ->
            Log.d(TAG, "Observed value $newValue")
            responseData.removeObservers(activity)
            newValue.onFailure { t -> result.error("yubikit.error", t.message, "") }
            newValue.onSuccess { t -> result.success(t) }
        }
    }


    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        Log.d(TAG, "Detached from engine")
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        Log.d(TAG, "Attached to activity")
        activity = binding.activity as FlutterActivity
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        Log.d(TAG, "Detached from activity for config changes")
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        Log.d(TAG, "Reattached to activity")
        activity = binding.activity as FlutterActivity
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivity() {
        Log.d(TAG, "Detached from activity")
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent): Boolean {
        Log.d(TAG, "Hey this is the data $data")
        if (data.hasExtra("PIV_ERROR")) {
            responseData.postValue(
                kotlin.Result.failure<Exception>(
                    Exception(
                        data.getStringExtra(
                            "PIV_ERROR"
                        )
                    )
                )
            )
        } else {
            when (requestCode) {
                SIGNATURE_REQUEST -> responseData.postValue(
                    kotlin.Result.success(
                        PivSignAction.getPivSignature(
                            data
                        )
                    )
                )
                DECRYPT_REQUEST -> responseData.postValue(
                    kotlin.Result.success(
                        PivDecryptAction.getPivDecrypted(
                            data
                        )
                    )
                )
            }
        }
        return true
    }

}
