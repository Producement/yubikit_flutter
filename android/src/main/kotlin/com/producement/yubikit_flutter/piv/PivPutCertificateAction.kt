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
import java.io.ByteArrayInputStream
import java.security.cert.CertificateFactory
import java.security.cert.X509Certificate

class PivPutCertificateAction : PivAction() {
    companion object {
        private const val TAG = "PivPutCertificateAction"
        fun pivPutCertificateIntent(
            context: Context,
            pin: String,
            slot: Int,
            certificate: ByteArray,
            managementKeyType: Byte,
            managementKey: ByteArray,
        ): Intent {
            Log.d(TAG, "Creating intent")
            val intent =
                YubiKeyPromptActivity.createIntent(context, PivPutCertificateAction::class.java)
            intent.putExtra("PIV_PIN", pin)
            intent.putExtra("PIV_CERTIFICATE", certificate)
            intent.putExtra("PIV_SLOT", slot)
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
        try {
            Log.d(TAG, "Yubikey connection created")
            val pin = extras.getString("PIV_PIN")!!
            val slot = extras.getInt("PIV_SLOT")
            val certificateData = extras.getByteArray("PIV_CERTIFICATE")!!
            val managementKeyType = extras.getByte("PIV_MANAGEMENT_KEY_TYPE")
            val managementKey = extras.getByteArray("PIV_MANAGEMENT_KEY")!!
            val pivSession = PivSession(connection)
            pivSession.verifyPin(pin.toCharArray())
            pivSession.authenticate(ManagementKeyType.fromValue(managementKeyType), managementKey)
            val cf = CertificateFactory.getInstance("X.509")
            val certificate = cf.generateCertificate(ByteArrayInputStream(certificateData))
            pivSession.putCertificate(Slot.fromValue(slot), certificate as X509Certificate)
            Log.d(TAG, "Certificate data")
            return result()
        } catch (e: Exception) {
            commandState.cancel()
            Log.e(TAG, "Something went wrong", e)
            val result = Intent()
            result.putExtra("PIV_ERROR", e.localizedMessage)
            return Pair(Activity.RESULT_OK, result)
        }
    }
}