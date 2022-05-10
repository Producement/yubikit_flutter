package com.producement.yubikit_flutter

import android.util.Log
import androidx.lifecycle.MutableLiveData
import com.yubico.yubikit.android.YubiKitManager
import com.yubico.yubikit.android.transport.nfc.NfcConfiguration
import com.yubico.yubikit.android.transport.nfc.NfcNotAvailable
import com.yubico.yubikit.android.transport.usb.UsbConfiguration
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
    private var eventSink: MutableLiveData<EventChannel.EventSink?> = MutableLiveData()

    sealed class SmartCardTask(private val result: MethodChannel.Result) {
        fun doWithConnection(
            smartCardConnection: Result<SmartCardConnection, IOException>
        ) {
            try {
                doWithConnection(smartCardConnection.value)
            } catch (e: Exception) {
                result.error("smart.card.error", e.localizedMessage, "")
            }
        }

        open fun doWithConnection(smartCardConnection: SmartCardConnection) {
            throw NotImplementedError("This should be implemented!")

        }
    }

    class SendCommandTask(private val apdu: ByteArray, private val result: MethodChannel.Result) :
        SmartCardTask(result) {
        override fun doWithConnection(
            smartCardConnection: SmartCardConnection
        ) {
            Log.d(TAG, "Executing command: ${apdu.toHex()}")
            result.success(smartCardConnection.sendAndReceive(apdu))
        }
    }

    class SelectApplicationTask(
        private val application: ByteArray,
        private val result: MethodChannel.Result
    ) :
        SmartCardTask(result) {
        override fun doWithConnection(
            smartCardConnection: SmartCardConnection
        ) {
            Log.d(TAG, "Selecting application: ${application.toHex()}")
            val protocol = SmartCardProtocol(smartCardConnection)
            result.success(protocol.select(application))
        }
    }

    class CloseConnection(private val result: MethodChannel.Result) : SmartCardTask(result) {
        override fun doWithConnection(smartCardConnection: SmartCardConnection) {
            Log.d(TAG, "Closing connection")
            result.success(null)
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "start" -> {
                Log.d(TAG, "Starting connection")
                startNfcDiscovery()
                yubiKeyDevice.observe(activity) { device ->
                    if (device != null) {
                        Log.d(TAG, "Received device")
                        device.requestConnection(SmartCardConnection::class.java) {
                            Log.d(TAG, "Received connection")
                            while (true) {
                                Log.d(TAG, "Polling for next task")
                                when (val task = workQueue.poll(5, TimeUnit.SECONDS)) {
                                    is CloseConnection -> {
                                        task.doWithConnection(it);break
                                    }
                                    is SelectApplicationTask, is SendCommandTask -> {
                                        task.doWithConnection(it)
                                    }
                                    null -> {
                                        Log.d(TAG, "Timed out");break
                                    }
                                }
                            }
                            Log.d(TAG, "No more tasks")
                        }
                    } else {
                        Log.d(TAG, "No device")
                    }
                }
            }
            "stop" -> {
                Log.d(TAG, "Stop connection")
                workQueue.add(CloseConnection(result))
                yubiKitManager.stopNfcDiscovery(activity)
            }
            "sendCommand" -> {
                val arguments = call.arguments<List<Any>>()
                val command = arguments[0] as ByteArray
                Log.d(TAG, "Sending command: ${command.toHex()}")
                workQueue.add(SendCommandTask(command, result))
            }
            "selectApplication" -> {
                val arguments = call.arguments<List<Any>>()
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
            eventSink.value?.success("deviceConnected")
            device.setOnClosed {
                Log.d(TAG, "USB device disconnected")
                activity.runOnUiThread {
                    eventSink.value?.success("deviceDisconnected")
                }
                yubiKeyDevice.postValue(null)
            }
        }
    }

    private fun startNfcDiscovery() {
        nfcDiscoveryEnabled = true
        Log.d(TAG, "Starting NFC discovery")
        try {
            yubiKitManager.startNfcDiscovery(nfcConfiguration, activity) { device ->
                Log.d(TAG, "NFC Session started $device")
                yubiKeyDevice.apply {
                    // Trigger new value, then removal
                    activity.runOnUiThread {
                        value = device
                        eventSink.value?.success("deviceConnected")
                        yubiKeyDevice.postValue(null)
                        eventSink.value?.success("deviceDisconnected")
                    }
                }
            }
        } catch (e: NfcNotAvailable) {
            Log.e(TAG, "Error starting NFC listening", e)
        }
    }

    private fun stopDiscovery() {
        Log.d(TAG, "Stopping discovery")
        nfcDiscoveryEnabled = false
        yubiKeyDevice.value = null
        yubiKitManager.stopNfcDiscovery(activity)
        yubiKitManager.stopUsbDiscovery()
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity as FlutterActivity
        yubiKitManager = YubiKitManager(activity)
        startDiscovery()
    }

    override fun onDetachedFromActivityForConfigChanges() {
        yubiKitManager.stopNfcDiscovery(activity)
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity as FlutterActivity
        if (nfcDiscoveryEnabled) {
            startNfcDiscovery()
        }
    }

    override fun onDetachedFromActivity() {
        stopDiscovery()
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink.postValue(events)
    }

    override fun onCancel(arguments: Any?) {
        eventSink.postValue(null)
    }
}