package com.producement.yubikit_flutter

import android.util.Log
import androidx.lifecycle.*
import com.producement.yubikit_flutter.smartcard.CloseConnection
import com.producement.yubikit_flutter.smartcard.SelectApplicationTask
import com.producement.yubikit_flutter.smartcard.SendCommandTask
import com.producement.yubikit_flutter.smartcard.SmartCardTask
import com.yubico.yubikit.android.YubiKitManager
import com.yubico.yubikit.android.transport.nfc.NfcConfiguration
import com.yubico.yubikit.android.transport.nfc.NfcNotAvailable
import com.yubico.yubikit.android.transport.usb.UsbConfiguration
import com.yubico.yubikit.core.Transport
import com.yubico.yubikit.core.YubiKeyDevice
import com.yubico.yubikit.core.smartcard.SmartCardConnection
import com.yubico.yubikit.core.smartcard.SmartCardProtocol
import com.yubico.yubikit.core.util.Result
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.IOException
import java.util.concurrent.LinkedBlockingQueue
import java.util.concurrent.TimeUnit

fun ByteArray.toHex(): String =
    joinToString(separator = "") { eachByte -> "%02x".format(eachByte) }

class YubikitSmartCardMethodCallHandler : MethodChannel.MethodCallHandler, ActivityAware,
    EventChannel.StreamHandler {

    private val workQueue = LinkedBlockingQueue<SmartCardTask>()

    companion object {
        const val TAG = "YKSCMethodCallHandler"
    }

    private lateinit var yubiKitManager: YubiKitManager
    private lateinit var activity: FlutterActivity
    private val nfcConfiguration = NfcConfiguration()
    private val yubiKeyDevice: MutableLiveData<YubiKeyDevice?> = MutableLiveData()
    private var nfcDiscoveryEnabled = false
    private val events: MutableLiveData<String> = MutableLiveData()

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "start" -> {
                Log.d(TAG, "Starting connection")
                if (yubiKeyDevice.hasActiveObservers()) {
                    Log.d(TAG, "Existing observer, skipping")
                } else {
                    workQueue.clear()
                    Log.d(TAG, "Starting to observe device events")
                    yubiKeyDevice.observe(activity) { device ->
                        if (device != null) {
                            Log.d(TAG, "Received device")
                            device.requestConnection(SmartCardConnection::class.java) {
                                Log.d(TAG, "Received connection")
                                while (true) {
                                    Log.d(TAG, "Polling for next task")
                                    try {
                                        when (val task = workQueue.poll(5, TimeUnit.SECONDS)) {
                                            is CloseConnection -> {
                                                activity.runOnUiThread {
                                                    yubiKeyDevice.removeObservers(activity)
                                                    yubiKitManager.stopNfcDiscovery(activity)
                                                }
                                                task.doWithConnection(it);break
                                            }
                                            is SelectApplicationTask, is SendCommandTask -> {
                                                task.doWithConnection(it)
                                            }
                                            null -> {
                                                activity.runOnUiThread {
                                                    yubiKeyDevice.removeObservers(activity)
                                                    yubiKitManager.stopNfcDiscovery(activity)
                                                }
                                                Log.d(TAG, "Timed out");break
                                            }
                                        }
                                    } catch (e: Exception) {
                                        Log.e(TAG, "Exception during command processing", e)
                                        yubiKeyDevice.removeObservers(activity)
                                    }
                                }
                                Log.d(TAG, "No more tasks")
                                if (device.transport == Transport.NFC) {
                                    yubiKeyDevice.postValue(null)
                                    events.postValue("deviceDisconnected")
                                }
                            }
                        } else {
                            Log.d(TAG, "No device")
                        }

                    }
                }
                startNfcDiscovery()
                result.success(null)
            }
            "stop" -> {
                Log.d(TAG, "Stop connection")
                workQueue.add(CloseConnection(result))
            }
            "sendCommand" -> {
                val arguments = call.arguments<List<Any>>()!!
                val command = arguments[0] as ByteArray
                Log.d(TAG, "Sending command: ${command.toHex()}")
                workQueue.add(SendCommandTask(command, result))
            }
            "selectApplication" -> {
                val arguments = call.arguments<List<Any>>()!!
                val application = arguments[0] as ByteArray
                Log.d(TAG, "Sending select application command: ${application.toHex()}")
                workQueue.add(SelectApplicationTask(application, result))
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    private fun startDiscovery() {
        Log.d(TAG, "Starting discovery")
        yubiKitManager.startUsbDiscovery(UsbConfiguration()) { device ->
            Log.d(TAG, "USB device connected")
            yubiKeyDevice.postValue(device)
            events.postValue("deviceConnected")
            device.setOnClosed {
                Log.d(TAG, "USB device disconnected")
                yubiKeyDevice.postValue(null)
                events.postValue("deviceDisconnected")
            }
        }
    }

    private fun startNfcDiscovery() {
        nfcDiscoveryEnabled = true
        Log.d(TAG, "Starting NFC discovery")
        try {
            yubiKitManager.startNfcDiscovery(nfcConfiguration, activity) { device ->
                Log.d(TAG, "NFC Session started $device")
                yubiKeyDevice.postValue(device)
                events.postValue("deviceConnected")
            }
        } catch (e: NfcNotAvailable) {
            Log.e(TAG, "Error starting NFC listening", e)
        }
    }

    private fun stopDiscovery() {
        Log.d(TAG, "Stopping discovery")
        nfcDiscoveryEnabled = false
        yubiKeyDevice.value = null
        yubiKeyDevice.removeObservers(activity)
        yubiKitManager.stopNfcDiscovery(activity)
        yubiKitManager.stopUsbDiscovery()
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        Log.d(TAG, "Attached to activity")
        activity = binding.activity as FlutterActivity
        yubiKitManager = YubiKitManager(activity)
        startDiscovery()
    }

    override fun onDetachedFromActivityForConfigChanges() {
        Log.d(TAG, "Detatching for config changes")
        yubiKitManager.stopNfcDiscovery(activity)
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        Log.d(TAG, "Reattaching from config changes")
        activity = binding.activity as FlutterActivity
        if (nfcDiscoveryEnabled) {
            startNfcDiscovery()
        }
    }

    override fun onDetachedFromActivity() {
        stopDiscovery()
    }

    override fun onListen(arguments: Any?, eventsSink: EventChannel.EventSink) {
        Log.d(TAG, "Registering event sink")
        events.observe(activity) {
            try {
                Log.d(TAG, "Sending event: $it")
                eventsSink.success(it)
            } catch (e: Exception) {
                Log.e(TAG, "Sending event failed", e)
            }
        }
        if (yubiKeyDevice.value != null) {
            events.postValue("deviceConnected")
        } else {
            events.postValue("deviceDisconnected")
        }
    }

    override fun onCancel(arguments: Any?) {
        Log.d(TAG, "Deregistering event sink")
        events.removeObservers(activity)
    }
}