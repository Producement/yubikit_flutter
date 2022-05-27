package com.producement.yubikit_flutter.smartcard

import android.app.Activity
import android.content.Intent
import android.util.Log
import com.producement.yubikit_flutter.piv.PivSignAction
import com.yubico.yubikit.android.ui.YubiKeyPromptConnectionAction
import com.yubico.yubikit.core.application.CommandState
import com.yubico.yubikit.core.smartcard.ApduException
import com.yubico.yubikit.core.smartcard.SmartCardConnection
import com.yubico.yubikit.core.util.Pair
import com.yubico.yubikit.piv.KeyType
import com.yubico.yubikit.piv.PivSession
import com.yubico.yubikit.piv.Slot
import java.lang.Exception

abstract class SmartCardConnectionAction :
    YubiKeyPromptConnectionAction<SmartCardConnection>(SmartCardConnection::class.java) {
    companion object {
        private const val TAG = "SmartCardConnAction"
    }

    protected fun result(data: ByteArray? = null): Pair<Int, Intent> {
        val result = Intent()
        if (data != null) {
            result.putExtra("SC_RESULT", data)
        }
        return Pair(Activity.RESULT_OK, result)
    }

    protected fun intResult(data: Int? = null): Pair<Int, Intent> {
        val result = Intent()
        if (data != null) {
            result.putExtra("SC_RESULT", data)
        }
        return Pair(Activity.RESULT_OK, result)
    }

    protected fun tryWithCommand(
        commandState: CommandState,
        command: () -> Pair<Int, Intent>
    ): Pair<Int, Intent> {
        return try {
            command()
        } catch (e: Exception) {
            commandState.cancel()
            Log.e(TAG, "Something went wrong", e)
            val result = Intent()
            result.putExtra("SC_ERROR", e.localizedMessage)
            if (e is ApduException) {
                result.putExtra("SC_ERROR_DETAILS", e.sw)
            }
            Pair(Activity.RESULT_OK, result)
        }
    }
}