package com.producement.yubikit_flutter.piv;

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.util.Log
import com.yubico.yubikit.android.ui.YubiKeyPromptActivity
import com.yubico.yubikit.core.application.CommandState
import com.yubico.yubikit.core.smartcard.SmartCardConnection
import com.yubico.yubikit.core.util.Pair
import com.yubico.yubikit.piv.KeyType
import com.yubico.yubikit.piv.PivSession
import com.yubico.yubikit.piv.Slot
import java.lang.Exception
import java.security.Signature


class PivSignAction : PivAction() {

    companion object {
        private const val TAG = "PivSignAction"
        fun pivSignIntent(
            context: Context,
            pin: String, algorithm: String, slot: Int, keyType: Int, message: ByteArray,
        ): Intent {
            Log.d(TAG, "Creating intent")
            val intent = YubiKeyPromptActivity.createIntent(context, PivSignAction::class.java)
            intent.putExtra("PIV_PIN", pin)
            intent.putExtra("PIV_ALGORITHM", algorithm)
            intent.putExtra("PIV_SLOT", slot)
            intent.putExtra("PIV_KEY_TYPE", keyType)
            intent.putExtra("PIV_MESSAGE", message)
            return intent
        }

        fun getPivSignature(intent: Intent) = intent.getByteArrayExtra("PIV_RESULT")
    }

    override fun onYubiKeyConnection(
        connection: SmartCardConnection,
        extras: Bundle,
        commandState: CommandState
    ): Pair<Int, Intent> {
        try {
            Log.d(TAG, "Yubikey connection created")
            val pin = extras.getString("PIV_PIN")!!
            val algorithm = extras.getString("PIV_ALGORITHM")!!
            val slot = extras.getInt("PIV_SLOT")
            val keyType = extras.getInt("PIV_KEY_TYPE")
            val message = extras.getByteArray("PIV_MESSAGE")!!
            val pivSession = PivSession(connection)
            pivSession.verifyPin(pin.toCharArray())
            val signatureAlgorithm = getSignatureAlgorithm(algorithm)

            if (signatureAlgorithm == null) {
                val result = Intent()
                result.putExtra("PIV_ERROR", "unsupported.algorithm.error")
                return Pair(Activity.RESULT_OK, result)
            }

            val signature = pivSession.sign(
                Slot.fromValue(slot),
                KeyType.fromValue(keyType),
                message,
                signatureAlgorithm,
            )
            Log.d(TAG, "Signature generated")
            val result = Intent()
            result.putExtra("PIV_RESULT", signature)
            return Pair(Activity.RESULT_OK, result)
        } catch (e: Exception) {
            commandState.cancel()
            Log.e(TAG, "Something went wrong", e)
            val result = Intent()
            result.putExtra("PIV_ERROR", e.localizedMessage)
            return Pair(Activity.RESULT_OK, result)
        }
    }

    private fun getSignatureAlgorithm(algorithm: String): Signature? {
        return when (algorithm) {
            "rsaSignatureMessagePKCS1v15SHA512" -> Signature.getInstance("SHA512withRSA")
            "ecdsaSignatureMessageX962SHA256" -> Signature.getInstance("SHA256withECDSA")
            else -> null
        }
    }

}