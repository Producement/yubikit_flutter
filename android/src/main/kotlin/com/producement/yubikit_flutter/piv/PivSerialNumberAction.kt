package com.producement.yubikit_flutter.piv

import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.util.Log
import com.yubico.yubikit.android.ui.YubiKeyPromptActivity
import com.yubico.yubikit.core.application.CommandState
import com.yubico.yubikit.core.smartcard.SmartCardConnection
import com.yubico.yubikit.core.util.Pair
import com.yubico.yubikit.piv.PivSession

class PivSerialNumberAction : PivAction() {
    companion object {
        private const val TAG = "PivSerialNumberAction"
        fun pivSerialNumberIntent(context: Context): Intent {
            Log.d(TAG, "Creating intent")
            return YubiKeyPromptActivity.createIntent(context, PivSerialNumberAction::class.java)
        }
    }

    override fun onYubiKeyConnection(
        connection: SmartCardConnection,
        extras: Bundle,
        commandState: CommandState
    ): Pair<Int, Intent> {
        return tryWithCommand(commandState) {
            val pivSession = PivSession(connection)
            intResult(pivSession.serialNumber)
        }
    }
}