package com.producement.yubikit_flutter

import android.content.Intent
import android.util.Log
import androidx.annotation.NonNull
import androidx.lifecycle.MutableLiveData
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry

interface ResultHandler {
    fun handleResult(result: MethodChannel.Result)
}

class YubikitFlutterPlugin : FlutterPlugin, ActivityAware, PluginRegistry.ActivityResultListener,
    ResultHandler {
    private lateinit var pivChannel: MethodChannel
    private lateinit var smartCardChannel: MethodChannel
    private lateinit var smartCardMethodHandler: YubikitSmartCardMethodCallHandler
    private lateinit var pivMethodHandler: YubikitPivMethodCallHandler
    private lateinit var activityPluginBinding: ActivityPluginBinding
    private var responseData: MutableLiveData<Result<*>>? = null

    companion object {
        private const val TAG = "YubikitFlutter"
        const val SIGNATURE_REQUEST = 1
        const val DECRYPT_REQUEST = 2
        const val GENERATE_REQUEST = 3
        const val RESET_REQUEST = 4
        const val SET_PIN_REQUEST = 5
        const val SET_PUK_REQUEST = 6
        const val GET_CERTIFICATE_REQUEST = 7
        const val PUT_CERTIFICATE_REQUEST = 8
        const val SECRET_KEY_REQUEST = 9
        const val SERIAL_NUMBER_REQUEST = 10
        const val SMART_CARD_REQUEST = 11
    }

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        Log.d(TAG, "Attached to engine")
        pivChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "yubikit_flutter_piv")
        pivMethodHandler =
            YubikitPivMethodCallHandler(flutterPluginBinding.applicationContext, this)
        pivChannel.setMethodCallHandler(pivMethodHandler)

        smartCardChannel = MethodChannel(flutterPluginBinding.binaryMessenger, "yubikit_flutter_sc")
        smartCardMethodHandler =
            YubikitSmartCardMethodCallHandler(flutterPluginBinding.applicationContext, this)
        smartCardChannel.setMethodCallHandler(smartCardMethodHandler)
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
        this.activityPluginBinding = binding
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        Log.d(TAG, "Detached from activity for config changes")
        pivMethodHandler.onDetachedFromActivityForConfigChanges()
        smartCardMethodHandler.onDetachedFromActivityForConfigChanges()
        activityPluginBinding.removeActivityResultListener(this)
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        Log.d(TAG, "Reattached to activity")
        pivMethodHandler.onReattachedToActivityForConfigChanges(binding)
        smartCardMethodHandler.onReattachedToActivityForConfigChanges(binding)
        binding.addActivityResultListener(this)
        this.activityPluginBinding = binding
    }

    override fun onDetachedFromActivity() {
        Log.d(TAG, "Detached from activity")
        smartCardMethodHandler.onDetachedFromActivity()
        pivMethodHandler.onDetachedFromActivity()
        activityPluginBinding.removeActivityResultListener(this)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?): Boolean {
        Log.d(TAG, "This is the data ${data!!.toUri(0)}")
        val responseData = this.responseData
        if (responseData != null) {
            if (data.hasExtra("SC_ERROR")) {
                responseData.postValue(
                    Result.failure<Exception>(
                        Exception(
                            data.getStringExtra(
                                "SC_ERROR"
                            )
                        )
                    )
                )
            } else {
                when (requestCode) {
                    SIGNATURE_REQUEST, DECRYPT_REQUEST, GENERATE_REQUEST,
                    GET_CERTIFICATE_REQUEST, SECRET_KEY_REQUEST, SMART_CARD_REQUEST -> responseData.postValue(
                        Result.success(
                            data.getByteArrayExtra("SC_RESULT")
                        )
                    )
                    SERIAL_NUMBER_REQUEST -> responseData.postValue(
                        Result.success(
                            data.getIntExtra(
                                "SC_RESULT", 0
                            )
                        )
                    )
                    else -> return false
                }
            }
        }
        return true
    }

    override fun handleResult(result: MethodChannel.Result) {
        Log.d(TAG, "Registering observer")
        responseData = MutableLiveData()
        responseData!!.observe(activityPluginBinding.activity as FlutterActivity) { newValue ->
            Log.d(TAG, "Observed value $newValue")
            Log.d(TAG, "Observers removed")
            newValue.onFailure { t ->
                Log.d(TAG, "Received error")
                result.error(
                    "yubikit.error",
                    t.message,
                    ""
                )
            }
            newValue.onSuccess { t ->
                Log.d(TAG, "Received success")
                result.success(t)
            }
        }
    }

}
