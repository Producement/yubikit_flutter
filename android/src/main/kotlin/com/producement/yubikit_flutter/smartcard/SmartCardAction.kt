package com.producement.yubikit_flutter.smartcard

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.util.Log
import com.yubico.yubikit.android.ui.YubiKeyPromptActivity
import com.yubico.yubikit.core.application.CommandState
import com.yubico.yubikit.core.smartcard.SmartCardConnection
import com.yubico.yubikit.core.smartcard.SmartCardProtocol
import com.yubico.yubikit.core.util.Pair

class SmartCardAction : SmartCardConnectionAction() {

    companion object {
        private const val TAG = "SmartCardAction"
        fun smartCardIntent(context: Context, command: ByteArray, application: ByteArray): Intent {
            Log.d(TAG, "Creating intent")
            return YubiKeyPromptActivity.createIntent(context, SmartCardAction::class.java).also {
                it.putExtra("SC_COMMAND", command)
                it.putExtra("SC_APPLICATION", application)
            }
        }
    }

    override fun onYubiKeyConnection(
        connection: SmartCardConnection,
        extras: Bundle,
        commandState: CommandState
    ): Pair<Int, Intent> {
        return try {
            val protocol = SmartCardProtocol(connection)
            val command = extras.getByteArray("SC_COMMAND")!!
            val application = extras.getByteArray("SC_APPLICATION")!!
            Log.d(TAG, "Executing command $command on application $application")
            protocol.select(application)
            result(connection.sendAndReceive(command))
        } catch (e: Exception) {
            val result = Intent()
            result.putExtra("SC_ERROR", e.localizedMessage)
            Pair(Activity.RESULT_OK, result)
        }
    }
}