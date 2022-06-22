package com.producement.yubikit_flutter.smartcard

import android.app.Activity
import android.content.Intent
import android.util.Log
import com.producement.yubikit_flutter.piv.PivSignAction
import com.producement.yubikit_flutter.toHex
import com.yubico.yubikit.android.ui.YubiKeyPromptConnectionAction
import com.yubico.yubikit.core.application.CommandState
import com.yubico.yubikit.core.smartcard.*
import com.yubico.yubikit.core.util.Pair
import com.yubico.yubikit.piv.KeyType
import com.yubico.yubikit.piv.PivSession
import com.yubico.yubikit.piv.Slot
import java.io.IOException
import java.lang.Exception
import java.nio.ByteBuffer

abstract class SmartCardConnectionAction :
    YubiKeyPromptConnectionAction<SmartCardConnection>(SmartCardConnection::class.java) {
    companion object {
        private const val TAG = "SmartCardConnAction"
    }

    protected fun result(data: ByteArray? = null): Pair<Int, Intent> {
        val result = Intent()
        if (data != null) {
            result.putExtra("SC_RESULT", data)
        }
        return Pair(Activity.RESULT_OK, result)
    }

    protected fun result(data: List<ByteArray>): Pair<Int, Intent> {
        val result = Intent()
        result.putExtra("SC_RESULTS", ArrayList(data))
        return Pair(Activity.RESULT_OK, result)
    }

    protected fun intResult(data: Int? = null): Pair<Int, Intent> {
        val result = Intent()
        if (data != null) {
            result.putExtra("SC_RESULT", data)
        }
        return Pair(Activity.RESULT_OK, result)
    }

    protected fun tryWithCommand(
        commandState: CommandState,
        command: () -> Pair<Int, Intent>
    ): Pair<Int, Intent> {
        return try {
            command()
        } catch (e: Exception) {
            commandState.cancel()
            Log.e(TAG, "Something went wrong", e)
            val result = Intent()
            result.putExtra("SC_ERROR", e.localizedMessage)
            val cause = e.cause
            if (e is ApduException) {
                result.putExtra("SC_ERROR_DETAILS", e.sw)
            } else if (cause is ApduException) {
                result.putExtra("SC_ERROR_DETAILS", cause.sw)
            }
            Pair(Activity.RESULT_OK, result)
        }
    }

    fun sendCommand(
        protocol: SmartCardProtocol,
        command: ByteArray
    ): ByteArray = protocol.sendAndReceive(
        Apdu(
            command[0].toInt(),
            command[1].toInt(),
            command[2].toInt(),
            command[3].toInt(),
            command.drop(5).toByteArray()
        )
    )

    fun shortToBytes(sw: Short): ByteArray {
        val buffer = ByteBuffer.allocate(2)
        buffer.putShort(sw)
        return buffer.array()
    }

    fun intToBytes(sw: Int): ByteArray {
        val buffer = ByteBuffer.allocate(4)
        buffer.putInt(sw)
        return buffer.array()
    }

    fun verifyPin(
        verifyCommand: ByteArray?,
        protocol: SmartCardProtocol
    ) {
        if (verifyCommand != null && verifyCommand.isNotEmpty()) {
            Log.d(TAG, "Executing verify command ${verifyCommand.toHex()}")
            val result = sendCommand(protocol, verifyCommand)
            Log.d(TAG, "Result from verify: ${result.toHex()}")
        }
    }

    fun selectApplication(
        protocol: SmartCardProtocol,
        application: ByteArray
    ) {
        try {
            protocol.select(application)
        } catch (e: IOException) {
            val cause = e.cause
            if (cause is ApduException && isTerminated(cause)) {
                activateCardAndResume(protocol, application)
            } else {
                Log.w(TAG, e.message.toString(), e)
            }
        }
    }

    private fun isTerminated(e: ApduException) =
        e.sw == SW.CONDITIONS_NOT_SATISFIED || e.sw == SW.NO_INPUT_DATA

    private fun activateCardAndResume(
        protocol: SmartCardProtocol,
        application: ByteArray
    ) {
        val activateFileCommand = Apdu(0, 0x44, 0, 0, null)
        protocol.sendAndReceive(activateFileCommand)
        protocol.select(application)
    }

}