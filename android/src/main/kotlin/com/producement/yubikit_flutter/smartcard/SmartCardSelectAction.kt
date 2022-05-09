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


class SmartCardSelectAction : SmartCardConnectionAction() {
    companion object {
        private const val TAG = "SmartCardSelectAction"
        fun selectIntent(context: Context, application: ByteArray): Intent {
            Log.d(TAG, "Creating intent")
            return YubiKeyPromptActivity.createIntent(context, SmartCardSelectAction::class.java)
                .also {
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
            val application = extras.getByteArray("SC_APPLICATION")!!
            val protocol = SmartCardProtocol(connection)
            protocol.select(application)
            result(protocol.select(application))
        }
    }
}