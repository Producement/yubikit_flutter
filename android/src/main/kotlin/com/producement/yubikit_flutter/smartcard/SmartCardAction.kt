package com.producement.yubikit_flutter.smartcard

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
        fun sendCommandIntent(context: Context, apdu: ByteArray, application: ByteArray): Intent {
            Log.d(TAG, "Creating intent")
            return YubiKeyPromptActivity.createIntent(context, SmartCardAction::class.java)
                .also {
                    it.putExtra("SC_APDU", apdu)
                    it.putExtra("SC_APPLICATION", application)
                }
        }
    }

    override fun onYubiKeyConnection(
        connection: SmartCardConnection,
        extras: Bundle,
        commandState: CommandState
    ): Pair<Int, Intent> {
        return tryWithCommand(commandState) {
            val apdu = extras.getByteArray("SC_APDU")!!
            val application = extras.getByteArray("SC_APPLICATION")!!
            if (application.isNotEmpty()) {
                val protocol = SmartCardProtocol(connection)
                protocol.select(application)
            }
            val apduResult = connection.sendAndReceive(apdu)
            result(apduResult)
        }
    }
}