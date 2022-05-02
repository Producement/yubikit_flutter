package com.producement.yubikit_flutter.piv

import android.app.Activity
import android.content.Intent
import com.yubico.yubikit.android.ui.YubiKeyPromptConnectionAction
import com.yubico.yubikit.core.smartcard.SmartCardConnection
import com.yubico.yubikit.core.util.Pair

abstract class PivAction :
    YubiKeyPromptConnectionAction<SmartCardConnection>(SmartCardConnection::class.java) {
    protected fun result(data: ByteArray? = null): Pair<Int, Intent> {
        val result = Intent()
        if (data != null) {
            result.putExtra("PIV_RESULT", data)
        }
        return Pair(Activity.RESULT_OK, result)
    }
}