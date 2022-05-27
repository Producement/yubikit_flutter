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
import com.yubico.yubikit.piv.PivSession
import com.yubico.yubikit.piv.Slot
import javax.crypto.Cipher


class PivDecryptAction : PivAction() {

    companion object {
        private const val TAG = "PivDecryptAction"
        fun pivDecryptIntent(
            context: Context,
            pin: String, algorithm: String, slot: Int, message: ByteArray,
        ): Intent {
            Log.d(TAG, "Creating intent")
            val intent = YubiKeyPromptActivity.createIntent(context, PivDecryptAction::class.java)
            intent.putExtra("PIV_PIN", pin)
            intent.putExtra("PIV_ALGORITHM", algorithm)
            intent.putExtra("PIV_SLOT", slot)
            intent.putExtra("PIV_MESSAGE", message)
            return intent
        }
    }

    override fun onYubiKeyConnection(
        connection: SmartCardConnection,
        extras: Bundle,
        commandState: CommandState
    ): Pair<Int, Intent> {
        return tryWithCommand(commandState) {
            Log.d(TAG, "Yubikey connection created")
            val pin = extras.getString("PIV_PIN")!!
            val algorithm = extras.getString("PIV_ALGORITHM")!!
            val slot = extras.getInt("PIV_SLOT")
            val message = extras.getByteArray("PIV_MESSAGE")!!
            val pivSession = PivSession(connection)
            pivSession.verifyPin(pin.toCharArray())
            val encryptionAlgorithm = getEncryptionAlgorithm(algorithm)
            if (encryptionAlgorithm == null) {
                val result = Intent()
                result.putExtra("PIV_ERROR", "unsupported.algorithm.error")
                Pair(Activity.RESULT_OK, result)
            } else {
                val decryptedData = pivSession.decrypt(
                    Slot.fromValue(slot),
                    message,
                    encryptionAlgorithm,
                )
                Log.d(TAG, "Decrypted data")
                val result = Intent()
                result.putExtra("PIV_RESULT", decryptedData)
                Pair(Activity.RESULT_OK, result)
            }
        }
    }

    private fun getEncryptionAlgorithm(algorithm: String): Cipher? {
        return when (algorithm) {
            "rsaEncryptionPKCS1" -> Cipher.getInstance("RSA/NONE/PKCS1Padding")
            "rsaEncryptionOAEPSHA224" -> Cipher.getInstance("RSA/NONE/OAEPWithSHA-224AndMGF1Padding")
            else -> null
        }
    }

}