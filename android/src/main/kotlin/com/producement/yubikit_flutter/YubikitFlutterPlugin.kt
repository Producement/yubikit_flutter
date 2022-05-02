package com.producement.yubikit_flutter

import android.content.Context
import android.content.Intent
import android.util.Log
import androidx.annotation.NonNull
import androidx.lifecycle.MutableLiveData
import com.producement.yubikit_flutter.piv.PivDecryptAction
import com.producement.yubikit_flutter.piv.PivDecryptAction.Companion.pivDecryptIntent
import com.producement.yubikit_flutter.piv.PivGenerateAction
import com.producement.yubikit_flutter.piv.PivGenerateAction.Companion.pivGenerateIntent
import com.producement.yubikit_flutter.piv.PivResetAction
import com.producement.yubikit_flutter.piv.PivSignAction
import com.producement.yubikit_flutter.piv.PivSignAction.Companion.pivSignIntent
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry
import java.security.KeyFactory
import java.security.spec.X509EncodedKeySpec
import javax.crypto.Cipher


class YubikitFlutterPlugin : FlutterPlugin, MethodCallHandler, ActivityAware,
    PluginRegistry.ActivityResultListener {
    private lateinit var channel: MethodChannel
    private lateinit var context: Context
    private lateinit var activity: FlutterActivity
    private lateinit var binding: ActivityPluginBinding
    private var responseData: MutableLiveData<kotlin.Result<*>>? = null

    companion object {
        private const val TAG = "YubikitFlutter"
        private const val SIGNATURE_REQUEST = 1
        private const val DECRYPT_REQUEST = 2
        private const val GENERATE_REQUEST = 3
        private const val RESET_REQUEST = 4
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
            "pivReset" -> {
                val intent = PivResetAction.pivResetIntent(context)
                observeResponse(result)
                activity.startActivityForResult(intent, RESET_REQUEST)
            }
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
                val arguments = call.arguments<List<Any>>()
                val slot = arguments[0] as Int
                val algorithm = arguments[1] as String
                val pin = arguments[2] as String
                val message = arguments[3] as ByteArray
                val intent = pivDecryptIntent(context, pin, algorithm, slot, message)
                observeResponse(result)
                activity.startActivityForResult(intent, DECRYPT_REQUEST)
            }
            "pivGenerateKey" -> {
                val arguments = call.arguments<List<Any>>()
                val slot = arguments[0] as Int
                val keyType = arguments[1] as Int
                val pinPolicy = arguments[2] as Int
                val touchPolicy = arguments[3] as Int
                val pin = arguments[4] as String
                val managementKeyType = arguments[5] as Int
                val managementKey = arguments[6] as ByteArray
                val intent =
                    pivGenerateIntent(
                        context,
                        pin,
                        slot,
                        keyType,
                        pinPolicy,
                        touchPolicy,
                        managementKeyType.toByte(),
                        managementKey
                    )
                observeResponse(result)
                activity.startActivityForResult(intent, GENERATE_REQUEST)
            }
            "pivEncryptWithKey" -> {
                val arguments = call.arguments<List<Any>>()
                val publicKeyData = arguments[0] as ByteArray
                val data = arguments[1] as ByteArray
                val publicKey =
                    KeyFactory.getInstance("RSA").generatePublic(X509EncodedKeySpec(publicKeyData))
                val encryptCipher = Cipher.getInstance("RSA/NONE/PKCS1Padding")
                encryptCipher.init(Cipher.ENCRYPT_MODE, publicKey)
                val encryptedData = encryptCipher.doFinal(data)
                result.success(encryptedData)
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun observeResponse(result: Result) {
        Log.d(TAG, "Registering observer")
        responseData = MutableLiveData()
        responseData!!.observe(activity) { newValue ->
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


    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        Log.d(TAG, "Detached from engine")
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        Log.d(TAG, "Attached to activity")
        activity = binding.activity as FlutterActivity
        this.binding = binding
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        Log.d(TAG, "Detached from activity for config changes")
        binding.removeActivityResultListener(this)
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        Log.d(TAG, "Reattached to activity")
        activity = binding.activity as FlutterActivity
        this.binding = binding
        binding.addActivityResultListener(this)
    }

    override fun onDetachedFromActivity() {
        Log.d(TAG, "Detached from activity")
        binding.removeActivityResultListener(this)
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent): Boolean {
        Log.d(TAG, "This is the data ${data.toUri(0)}")
        val responseData = this.responseData
        if (responseData != null) {
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
                    GENERATE_REQUEST -> responseData.postValue(
                        kotlin.Result.success(PivGenerateAction.getPivGenerate(data))
                    )
                    RESET_REQUEST -> responseData.postValue(kotlin.Result.success(null))
                }
            }
        }
        return true
    }

}
