package com.producement.yubikit_flutter.smartcard

import android.content.Context
import android.content.Intent
import android.nfc.Tag
import android.os.Bundle
import android.util.Log
import com.producement.yubikit_flutter.toHex
import com.yubico.yubikit.android.ui.YubiKeyPromptActivity
import com.yubico.yubikit.core.application.CommandState
import com.yubico.yubikit.core.smartcard.Apdu
import com.yubico.yubikit.core.smartcard.ApduException
import com.yubico.yubikit.core.smartcard.SmartCardConnection
import com.yubico.yubikit.core.smartcard.SmartCardProtocol
import com.yubico.yubikit.core.util.Pair

class SmartCardAction : SmartCardConnectionAction() {

    companion object {
        private const val TAG = "SmartCardAction"
        fun smartCardIntent(
            context: Context,
            command: ByteArray,
            verifyCommand: ByteArray?,
            application: ByteArray,
        ): Intent {
            Log.d(TAG, "Creating intent")
            return YubiKeyPromptActivity.createIntent(context, SmartCardAction::class.java).also {
                it.putExtra("SC_COMMAND", command)
                it.putExtra("SC_APPLICATION", application)
                verifyCommand?.let { cmd ->
                    it.putExtra("SC_VERIFY", cmd)
                }
            }
        }
    }

    override fun onYubiKeyConnection(
        connection: SmartCardConnection,
        extras: Bundle,
        commandState: CommandState
    ): Pair<Int, Intent> {
        return tryWithCommand(commandState) {
            Log.d(TAG, "Starting Yubikey connection")
            val protocol = SmartCardProtocol(connection)
            val command = extras.getByteArray("SC_COMMAND")!!
            val verifyCommand = extras.getByteArray("SC_VERIFY")
            val application = extras.getByteArray("SC_APPLICATION")!!
            Log.d(TAG, "Executing command ${command.toHex()} on application ${application.toHex()}")
            selectProtocol(protocol, application)
            if (verifyCommand != null && verifyCommand.isNotEmpty()) {
                Log.d(TAG, "Executing verify command ${verifyCommand.toHex()}")
                val result = protocol.sendAndReceive(
                    Apdu(
                        verifyCommand[0].toInt(),
                        verifyCommand[1].toInt(),
                        verifyCommand[2].toInt(),
                        verifyCommand[3].toInt(),
                        verifyCommand.drop(5).toByteArray()
                    )
                )
                Log.d(TAG, "Result from verify: ${result.toHex()}")
            }
            result(
                protocol.sendAndReceive(
                    Apdu(
                        command[0].toInt(),
                        command[1].toInt(),
                        command[2].toInt(),
                        command[3].toInt(),
                        command.drop(5).toByteArray()
                    )
                )
            )
        }
    }

    private fun selectProtocol(
        protocol: SmartCardProtocol,
        application: ByteArray
    ) {
        try {
            protocol.select(application)
        } catch (e: ApduException) {
            Log.w(TAG, e.message.toString(), e)
        }
    }
}