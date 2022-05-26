package com.producement.yubikit_flutter

import android.content.Context
import android.content.Intent
import android.util.Log
import androidx.annotation.NonNull
import androidx.lifecycle.MutableLiveData
import com.producement.yubikit_flutter.YubikitFlutterPlugin.Companion.DECRYPT_REQUEST
import com.producement.yubikit_flutter.YubikitFlutterPlugin.Companion.GENERATE_REQUEST
import com.producement.yubikit_flutter.YubikitFlutterPlugin.Companion.GET_CERTIFICATE_REQUEST
import com.producement.yubikit_flutter.YubikitFlutterPlugin.Companion.PUT_CERTIFICATE_REQUEST
import com.producement.yubikit_flutter.YubikitFlutterPlugin.Companion.RESET_REQUEST
import com.producement.yubikit_flutter.YubikitFlutterPlugin.Companion.SECRET_KEY_REQUEST
import com.producement.yubikit_flutter.YubikitFlutterPlugin.Companion.SERIAL_NUMBER_REQUEST
import com.producement.yubikit_flutter.YubikitFlutterPlugin.Companion.SET_PIN_REQUEST
import com.producement.yubikit_flutter.YubikitFlutterPlugin.Companion.SET_PUK_REQUEST
import com.producement.yubikit_flutter.YubikitFlutterPlugin.Companion.SIGNATURE_REQUEST
import com.producement.yubikit_flutter.piv.*
import com.yubico.yubikit.piv.KeyType
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.PluginRegistry
import java.security.KeyFactory
import java.security.spec.X509EncodedKeySpec
import javax.crypto.Cipher

class YubikitPivMethodCallHandler(
    private val context: Context,
    private val resultHandler: ResultHandler
) : MethodChannel.MethodCallHandler,
    ActivityAware {

    private lateinit var activity: FlutterActivity
    private lateinit var binding: ActivityPluginBinding

    companion object {
        private const val TAG = "YubikitPivHandler"

    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: MethodChannel.Result) {
        Log.d(TAG, "Method ${call.method} called")
        when (call.method) {
            "pivSerialNumber" -> {
                val intent = PivSerialNumberAction.pivSerialNumberIntent(context)
                resultHandler.handleResult(result)
                activity.startActivityForResult(intent, SERIAL_NUMBER_REQUEST)
            }
            "pivSetPin" -> {
                val arguments = call.arguments<List<Any>>()!!
                val newPin = arguments[0] as String
                val oldPin = arguments[1] as String
                val intent = PivSetPinAction.pivSetPinIntent(context, oldPin, newPin)
                resultHandler.handleResult(result)
                activity.startActivityForResult(intent, SET_PIN_REQUEST)
            }
            "pivSetPuk" -> {
                val arguments = call.arguments<List<Any>>()!!
                val newPuk = arguments[0] as String
                val oldPuk = arguments[1] as String
                val intent = PivSetPukAction.pivSetPukIntent(context, oldPuk, newPuk)
                resultHandler.handleResult(result)
                activity.startActivityForResult(intent, SET_PUK_REQUEST)
            }
            "pivReset" -> {
                val intent = PivResetAction.pivResetIntent(context)
                resultHandler.handleResult(result)
                activity.startActivityForResult(intent, RESET_REQUEST)
            }
            "pivSignWithKey" -> {
                val arguments = call.arguments<List<Any>>()!!
                val slot = arguments[0] as Int
                val keyType = arguments[1] as Int
                val algorithm = arguments[2] as String
                val pin = arguments[3] as String
                val message = arguments[4] as ByteArray
                val intent =
                    PivSignAction.pivSignIntent(context, pin, algorithm, slot, keyType, message)
                resultHandler.handleResult(result)
                activity.startActivityForResult(intent, SIGNATURE_REQUEST)
            }
            "pivDecryptWithKey" -> {
                val arguments = call.arguments<List<Any>>()!!
                val slot = arguments[0] as Int
                val algorithm = arguments[1] as String
                val pin = arguments[2] as String
                val message = arguments[3] as ByteArray
                val intent =
                    PivDecryptAction.pivDecryptIntent(context, pin, algorithm, slot, message)
                resultHandler.handleResult(result)
                activity.startActivityForResult(intent, DECRYPT_REQUEST)
            }
            "pivGenerateKey" -> {
                val arguments = call.arguments<List<Any>>()!!
                val slot = arguments[0] as Int
                val keyType = arguments[1] as Int
                val pinPolicy = arguments[2] as Int
                val touchPolicy = arguments[3] as Int
                val pin = arguments[4] as String
                val managementKeyType = arguments[5] as Int
                val managementKey = arguments[6] as ByteArray
                val intent =
                    PivGenerateAction.pivGenerateIntent(
                        context,
                        pin,
                        slot,
                        keyType,
                        pinPolicy,
                        touchPolicy,
                        managementKeyType.toByte(),
                        managementKey
                    )
                resultHandler.handleResult(result)
                activity.startActivityForResult(intent, GENERATE_REQUEST)
            }
            "pivCalculateSecretKey" -> {
                val arguments = call.arguments<List<Any>>()!!
                val slot = arguments[0] as Int
                val pin = arguments[1] as String
                val publicKeyData = arguments[2] as ByteArray
                val managementKeyType = arguments[3] as Int
                val managementKey = arguments[4] as ByteArray
                val intent =
                    PivSecretKeyAction.pivSecretKeyIntent(
                        context,
                        pin,
                        slot,
                        publicKeyData,
                        managementKeyType.toByte(),
                        managementKey
                    )
                resultHandler.handleResult(result)
                activity.startActivityForResult(intent, SECRET_KEY_REQUEST)
            }
            "pivGetCertificate" -> {
                val arguments = call.arguments<List<Any>>()!!
                val slot = arguments[0] as Int
                val pin = arguments[1] as String
                val intent = PivGetCertificateAction.pivGetCertificateIntent(context, pin, slot)
                resultHandler.handleResult(result)
                activity.startActivityForResult(
                    intent,
                    GET_CERTIFICATE_REQUEST
                )
            }
            "pivPutCertificate" -> {
                val arguments = call.arguments<List<Any>>()!!
                val slot = arguments[0] as Int
                val pin = arguments[1] as String
                val data = arguments[2] as ByteArray
                val managementKeyType = arguments[3] as Int
                val managementKey = arguments[4] as ByteArray
                val intent =
                    PivPutCertificateAction.pivPutCertificateIntent(
                        context,
                        pin,
                        slot,
                        data,
                        managementKeyType.toByte(),
                        managementKey
                    )
                resultHandler.handleResult(result)
                activity.startActivityForResult(
                    intent,
                    PUT_CERTIFICATE_REQUEST
                )
            }
            "pivEncryptWithKey" -> {
                val arguments = call.arguments<List<Any>>()!!
                val keyType = arguments[0] as Int
                val publicKeyData = arguments[1] as ByteArray
                val data = arguments[2] as ByteArray
                val algorithm = when (KeyType.fromValue(keyType)) {
                    KeyType.RSA1024, KeyType.RSA2048 -> "RSA"
                    KeyType.ECCP256, KeyType.ECCP384 -> "EC"
                    else -> {
                        result.error("key.type.error", "Unknown key type: $keyType", "")
                        return
                    }
                }
                val publicKey =
                    KeyFactory.getInstance(algorithm)
                        .generatePublic(X509EncodedKeySpec(publicKeyData))
                val encryptCipher = Cipher.getInstance("$algorithm/NONE/PKCS1Padding")
                encryptCipher.init(Cipher.ENCRYPT_MODE, publicKey)
                val encryptedData = encryptCipher.doFinal(data)
                result.success(encryptedData)
            }
            else -> {
                result.notImplemented()
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