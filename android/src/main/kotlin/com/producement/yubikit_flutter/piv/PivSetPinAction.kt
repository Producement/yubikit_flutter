package com.producement.yubikit_flutter.piv

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.util.Log
import com.yubico.yubikit.android.ui.YubiKeyPromptActivity
import com.yubico.yubikit.core.application.CommandState
import com.yubico.yubikit.core.smartcard.SmartCardConnection
import com.yubico.yubikit.core.util.Pair
import com.yubico.yubikit.piv.PivSession

class PivSetPinAction : PivAction() {
    companion object {
        private const val TAG = "PivSetPinAction"
        fun pivSetPinIntent(context: Context, oldPin: String, newPin: String): Intent {
            Log.d(TAG, "Creating intent")
            return YubiKeyPromptActivity.createIntent(context, PivSetPinAction::class.java).also {
                it.putExtra("PIV_OLD_PIN", oldPin)
                it.putExtra("PIV_NEW_PIN", newPin)
            }
        }
    }

    override fun onYubiKeyConnection(
        connection: SmartCardConnection,
        extras: Bundle,
        commandState: CommandState
    ): Pair<Int, Intent> {
        return try {
            val oldPin = extras.getString("PIV_OLD_PIN")!!
            val newPin = extras.getString("PIV_NEW_PIN")!!

            val pivSession = PivSession(connection)
            pivSession.changePin(oldPin.toCharArray(), newPin.toCharArray())
            result()
        } catch (e: Exception) {
            val result = Intent()
            result.putExtra("PIV_ERROR", e.localizedMessage)
            Pair(Activity.RESULT_OK, result)
        }
    }
}