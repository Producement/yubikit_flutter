package com.producement.yubikit_flutter

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.util.Log
import com.yubico.yubikit.android.ui.YubiKeyPromptActivity
import com.yubico.yubikit.core.application.CommandState
import com.yubico.yubikit.core.smartcard.ApduException
import com.yubico.yubikit.core.smartcard.SmartCardConnection
import com.yubico.yubikit.core.util.Pair
import com.yubico.yubikit.piv.*

class PivGenerateAction : PivAction() {
    companion object {
        private const val TAG = "PivGenerateAction"
        fun pivGenerateIntent(
            context: Context,
            pin: String,
            slot: Int,
            keyType: Int,
            pinPolicy: Int,
            touchPolicy: Int,
            managementKeyType: Byte,
            managementKey: ByteArray,
        ): Intent {
            Log.d(TAG, "Creating intent")
            val intent = YubiKeyPromptActivity.createIntent(context, PivGenerateAction::class.java)
            intent.putExtra("PIV_PIN", pin)
            intent.putExtra("PIV_KEY_TYPE", keyType)
            intent.putExtra("PIV_SLOT", slot)
            intent.putExtra("PIV_PIN_POLICY", pinPolicy)
            intent.putExtra("PIV_TOUCH_POLICY", touchPolicy)
            intent.putExtra("PIV_MANAGEMENT_KEY_TYPE", managementKeyType)
            intent.putExtra("PIV_MANAGEMENT_KEY", managementKey)
            return intent
        }

        fun getPivGenerate(intent: Intent) = intent.getByteArrayExtra("PIV_RESULT")
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
            val keyType = extras.getInt("PIV_KEY_TYPE")
            val managementKeyType = extras.getByte("PIV_MANAGEMENT_KEY_TYPE")
            val managementKey = extras.getByteArray("PIV_MANAGEMENT_KEY")!!
            val pinPolicy = extras.getInt("PIV_PIN_POLICY")
            val touchPolicy = extras.getInt("PIV_TOUCH_POLICY")

            val pivSession = PivSession(connection)
            pivSession.verifyPin(pin.toCharArray())
            pivSession.authenticate(ManagementKeyType.fromValue(managementKeyType), managementKey)

            val publicKey = pivSession.generateKey(
                Slot.fromValue(slot),
                KeyType.fromValue(keyType),
                PinPolicy.fromValue(pinPolicy),
                TouchPolicy.fromValue(touchPolicy),
            )
            Log.d(TAG, "Generated private key")
            val result = Intent()
            result.putExtra("PIV_RESULT", publicKey.encoded)
            return Pair(Activity.RESULT_OK, result)
        } catch (e: Exception) {
            commandState.cancel()
            Log.e(TAG, "Something went wrong", e)
            throw e
        }
    }
}