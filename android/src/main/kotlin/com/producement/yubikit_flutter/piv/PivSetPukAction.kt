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

class PivSetPukAction : PivAction() {
    companion object {
        private const val TAG = "PivSetPukAction"
        fun pivSetPukIntent(context: Context, oldPuk: String, newPuk: String): Intent {
            Log.d(TAG, "Creating intent")
            return YubiKeyPromptActivity.createIntent(context, PivSetPukAction::class.java).also {
                it.putExtra("PIV_OLD_PUK", oldPuk)
                it.putExtra("PIV_NEW_PUK", newPuk)
            }
        }
    }

    override fun onYubiKeyConnection(
        connection: SmartCardConnection,
        extras: Bundle,
        commandState: CommandState
    ): Pair<Int, Intent> {
        return try {
            val oldPuk = extras.getString("PIV_OLD_PUK")!!
            val newPuk = extras.getString("PIV_NEW_PUK")!!

            val pivSession = PivSession(connection)
            pivSession.changePuk(oldPuk.toCharArray(), newPuk.toCharArray())
            result()
        } catch (e: Exception) {
            val result = Intent()
            result.putExtra("PIV_ERROR", e.localizedMessage)
            Pair(Activity.RESULT_OK, result)
        }
    }
}