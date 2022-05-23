package com.producement.yubikit_flutter.smartcard

import android.util.Log
import com.producement.yubikit_flutter.YubikitSmartCardMethodCallHandler
import com.producement.yubikit_flutter.toHex
import com.yubico.yubikit.core.smartcard.SmartCardConnection
import com.yubico.yubikit.core.smartcard.SmartCardProtocol
import com.yubico.yubikit.core.util.Result
import io.flutter.plugin.common.MethodChannel
import java.io.IOException

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
        Log.d(YubikitSmartCardMethodCallHandler.TAG, "Executing command: ${apdu.toHex()}")
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
        Log.d(
            YubikitSmartCardMethodCallHandler.TAG,
            "Selecting application: ${application.toHex()}"
        )
        val protocol = SmartCardProtocol(smartCardConnection)
        result.success(protocol.select(application))
    }
}

class CloseConnection(private val result: MethodChannel.Result) :
    SmartCardTask(result) {
    override fun doWithConnection(smartCardConnection: SmartCardConnection) {
        Log.d(YubikitSmartCardMethodCallHandler.TAG, "Closing connection")
        result.success(null)
    }
}