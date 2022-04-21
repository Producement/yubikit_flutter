package com.producement.yubikit_flutter

import android.app.Activity
import androidx.annotation.NonNull
import com.yubico.yubikit.android.YubiKitManager
import com.yubico.yubikit.android.transport.nfc.NfcConfiguration
import com.yubico.yubikit.android.transport.nfc.NfcNotAvailable
import com.yubico.yubikit.android.transport.usb.UsbConfiguration
import com.yubico.yubikit.core.Logger
import com.yubico.yubikit.core.YubiKeyDevice
import com.yubico.yubikit.core.smartcard.SmartCardConnection
import com.yubico.yubikit.piv.KeyType
import com.yubico.yubikit.piv.PivSession
import com.yubico.yubikit.piv.Slot
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import java.security.Signature
import javax.crypto.Cipher


/** YubikitFlutterPlugin */
class YubikitFlutterPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    private lateinit var channel: MethodChannel
    private lateinit var yubikit: YubiKitManager
    private lateinit var activity: Activity
    private var device: YubiKeyDevice? = null
    private val nfcConfiguration = NfcConfiguration()

    override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(flutterPluginBinding.binaryMessenger, "yubikit_flutter")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(@NonNull call: MethodCall, @NonNull result: Result) {
        val yubikeyDevice = device
        if (yubikeyDevice == null) {
            result.error("no.device", "Device not found!", "")
            return
        }
        when (call.method) {
            "pivSignWithKey" -> {
                getSession(
                    yubikeyDevice,
                    { error ->
                        result.error(
                            "session.error",
                            error.localizedMessage,
                            ""
                        )
                    }) { pivSession ->
                    val arguments = call.arguments<Array<Any>>()
                    val slot = arguments[0] as Int
                    val keyType = arguments[1] as Int
                    val algorithm = arguments[2] as String
                    val pin = arguments[3] as String
                    val message = arguments[4] as ByteArray
                    pivSession.verifyPin(pin.toCharArray())
                    val signatureAlgorithm = getSignatureAlgorithm(algorithm)
                    if (signatureAlgorithm == null) {
                        result.error(
                            "unsupported.algorithm.error",
                            "Unsupported algorithm: $algorithm",
                            ""
                        )
                        return@getSession
                    }

                    val signature = pivSession.sign(
                        Slot.fromValue(slot),
                        KeyType.fromValue(keyType),
                        message,
                        signatureAlgorithm,
                    )
                    result.success(signature)
                }
            }
            "pivDecryptWithKey" -> {
                getSession(
                    yubikeyDevice,
                    { error ->
                        result.error(
                            "session.error",
                            error.localizedMessage,
                            ""
                        )
                    }) { pivSession ->
                    val arguments = call.arguments<Array<Any>>()
                    val slot = arguments[0] as Int
                    val algorithm = arguments[1] as String
                    val pin = arguments[2] as String
                    val message = arguments[3] as ByteArray
                    pivSession.verifyPin(pin.toCharArray())
                    val encryptionAlgorithm = getEncryptionAlgorithm(algorithm)
                    if (encryptionAlgorithm == null) {
                        result.error(
                            "unsupported.algorithm.error",
                            "Unsupported algorithm: $algorithm",
                            ""
                        )
                        return@getSession
                    }

                    val decryptedData = pivSession.decrypt(
                        Slot.fromValue(slot),
                        message,
                        encryptionAlgorithm,
                    )
                    result.success(decryptedData)
                }
            }
            "pivGetPublicKey" -> {
                getSession(
                    yubikeyDevice,
                    { error ->
                        result.error(
                            "session.error",
                            error.localizedMessage,
                            ""
                        )
                    }) { pivSession ->
                    val arguments = call.arguments<Array<Any>>()
                    val slot = arguments[0] as Int
                    val certificate = pivSession.getCertificate(Slot.fromValue(slot))
                    result.success(certificate.publicKey.encoded)
                }
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun getSignatureAlgorithm(algorithm: String): Signature? {
        return when (algorithm) {
            "rsaSignatureMessagePKCS1v15SHA512" -> Signature.getInstance("SHA512withRSA")
            "ecdsaSignatureMessageX962SHA256" -> Signature.getInstance("SHA256withECDSA")
            else -> null
        }
    }

    private fun getEncryptionAlgorithm(algorithm: String): Cipher? {
        return when (algorithm) {
            "rsaEncryptionPKCS1" -> Cipher.getInstance("RSA/NONE/PKCS1Padding")
            "rsaEncryptionOAEPSHA224" -> Cipher.getInstance("RSA/NONE/OAEPWithSHA-224AndMGF1Padding")
            else -> null
        }
    }

    private fun getSession(
        device: YubiKeyDevice,
        onError: (Throwable) -> Unit,
        callback: (PivSession) -> Unit
    ) {
        device.requestConnection(SmartCardConnection::class.java) {
            try {
                callback(PivSession(it.value))
            } catch (e: Throwable) {
                onError(e)
            }
        }
    }

    override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        yubikit = YubiKitManager(binding.activity)
        Logger.d("Enable listening")
        yubikit.startUsbDiscovery(UsbConfiguration()) { device ->
            Logger.d("USB device attached $device")
            this.device = device
            device.setOnClosed {
                Logger.d("Device removed $device")
                this.device = null
            }
        }
        try {
            yubikit.startNfcDiscovery(nfcConfiguration, binding.activity) { device ->
                Logger.d("NFC Session started $device")
                this.device = device
            }
        } catch (e: NfcNotAvailable) {
            Logger.e("Error starting NFC listening", e)
        }
    }

    override fun onDetachedFromActivityForConfigChanges() {
        yubikit.stopNfcDiscovery(activity)

    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        try {
            yubikit.startNfcDiscovery(nfcConfiguration, binding.activity) { device ->
                Logger.d("NFC Session started $device")
                this.device = device
            }
        } catch (e: NfcNotAvailable) {
            Logger.e("Error starting NFC listening", e)
        }
    }

    override fun onDetachedFromActivity() {
        yubikit.stopUsbDiscovery()
        yubikit.stopNfcDiscovery(activity)
    }
}
