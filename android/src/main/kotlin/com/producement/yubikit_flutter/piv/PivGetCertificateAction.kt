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
import com.yubico.yubikit.piv.Slot

class PivGetCertificateAction : PivAction() {
    companion object {
        private const val TAG = "PivGetCertificateAction"
        fun pivGetCertificateIntent(
            context: Context,
            pin: String,
            slot: Int,
        ): Intent {
            Log.d(TAG, "Creating intent")
            val intent =
                YubiKeyPromptActivity.createIntent(context, PivGetCertificateAction::class.java)
            intent.putExtra("PIV_PIN", pin)
            intent.putExtra("PIV_SLOT", slot)
            return intent
        }
    }

    override fun onYubiKeyConnection(
        connection: SmartCardConnection,
        extras: Bundle,
        commandState: CommandState
    ): Pair<Int, Intent> {
        try {
            Log.d(TAG, "Yubikey connection created")
            val pin = extras.getString("PIV_PIN")!!
            val slot = extras.getInt("PIV_SLOT")
            val pivSession = PivSession(connection)
            pivSession.verifyPin(pin.toCharArray())

            val certificate = pivSession.getCertificate(Slot.fromValue(slot))
            Log.d(TAG, "Certificate data")
            return result(certificate.encoded)
        } catch (e: Exception) {
            commandState.cancel()
            Log.e(TAG, "Something went wrong", e)
            val result = Intent()
            result.putExtra("PIV_ERROR", e.localizedMessage)
            return Pair(Activity.RESULT_OK, result)
        }
    }
}