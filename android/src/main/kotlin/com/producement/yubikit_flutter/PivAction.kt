package com.producement.yubikit_flutter

import com.yubico.yubikit.android.ui.YubiKeyPromptConnectionAction
import com.yubico.yubikit.core.smartcard.SmartCardConnection

abstract class PivAction :
    YubiKeyPromptConnectionAction<SmartCardConnection>(SmartCardConnection::class.java)