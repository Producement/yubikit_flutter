package com.producement.yubikit_flutter.smartcard

import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.util.Log
import com.producement.yubikit_flutter.toHex
import com.yubico.yubikit.android.ui.YubiKeyPromptActivity
import com.yubico.yubikit.core.application.CommandState
import com.yubico.yubikit.core.smartcard.*
import com.yubico.yubikit.core.util.Pair
import java.io.IOException
import java.nio.ByteBuffer

class SmartCardAction : SmartCardConnectionAction() {

    companion object {
        private const val TAG = "SmartCardAction"
        fun smartCardIntent(
            context: Context,
            commands: List<ByteArray>,
            verifyCommand: ByteArray?,
            application: ByteArray,
        ): Intent {
            Log.d(TAG, "Creating intent")
            return YubiKeyPromptActivity.createIntent(context, SmartCardAction::class.java).also {
                it.putExtra("SC_COMMANDS", commands.toTypedArray())
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
            val commands = extras.getSerializable("SC_COMMANDS") as Array<ByteArray>
            val verifyCommand = extras.getByteArray("SC_VERIFY")
            val application = extras.getByteArray("SC_APPLICATION")!!


            selectApplication(protocol, application)
            verifyPin(verifyCommand, protocol)
            result(commands.map { command ->
                Log.d(
                    TAG,
                    "Executing command ${command.toHex()} on application ${application.toHex()}"
                )
                try {
                    sendCommand(protocol, command)
                } catch (e: ApduException) {
                    shortToBytes(e.sw)
                }

            }
            )
        }
    }


}