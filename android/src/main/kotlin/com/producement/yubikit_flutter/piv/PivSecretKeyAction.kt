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
import com.yubico.yubikit.piv.ManagementKeyType
import com.yubico.yubikit.piv.PivSession
import com.yubico.yubikit.piv.Slot
import java.security.KeyFactory
import java.security.interfaces.ECPublicKey
import java.security.spec.ECPublicKeySpec
import java.security.spec.X509EncodedKeySpec

class PivSecretKeyAction : PivAction() {
    companion object {
        private const val TAG = "PivSecretKeyAction"
        fun pivSecretKeyIntent(
            context: Context,
            pin: String,
            slot: Int,
            publicKey: ByteArray,
            managementKeyType: Byte,
            managementKey: ByteArray,
        ): Intent {
            Log.d(TAG, "Creating intent")
            val intent = YubiKeyPromptActivity.createIntent(context, PivSecretKeyAction::class.java)
            intent.putExtra("PIV_PIN", pin)
            intent.putExtra("PIV_SLOT", slot)
            intent.putExtra("PIV_PUBLIC_KEY", publicKey)
            intent.putExtra("PIV_MANAGEMENT_KEY_TYPE", managementKeyType)
            intent.putExtra("PIV_MANAGEMENT_KEY", managementKey)
            return intent
        }
    }

    override fun onYubiKeyConnection(
        connection: SmartCardConnection,
        extras: Bundle,
        commandState: CommandState
    ): Pair<Int, Intent> {
        return try {
            val slot = extras.getInt("PIV_SLOT")
            val pin = extras.getString("PIV_PIN")!!
            val publicKeyData = extras.getByteArray("PIV_PUBLIC_KEY")
            val managementKeyType = extras.getByte("PIV_MANAGEMENT_KEY_TYPE")
            val managementKey = extras.getByteArray("PIV_MANAGEMENT_KEY")!!
            val pivSession = PivSession(connection)
            val publicKey =
                KeyFactory.getInstance("EC").generatePublic(X509EncodedKeySpec(publicKeyData))
            pivSession.verifyPin(pin.toCharArray())
            pivSession.authenticate(ManagementKeyType.fromValue(managementKeyType), managementKey)
            val key = pivSession.calculateSecret(Slot.fromValue(slot), publicKey as ECPublicKey)
            result(key)
        } catch (e: Exception) {
            val result = Intent()
            result.putExtra("PIV_ERROR", e.localizedMessage)
            Pair(Activity.RESULT_OK, result)
        }
    }
}