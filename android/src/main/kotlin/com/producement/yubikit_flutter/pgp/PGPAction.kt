package com.producement.yubikit_flutter.pgp

import com.producement.yubikit_flutter.smartcard.SmartCardConnectionAction
import com.yubico.yubikit.core.smartcard.Apdu
import com.yubico.yubikit.core.smartcard.SmartCardProtocol
import java.time.Instant
import java.util.*

abstract class PGPAction : SmartCardConnectionAction() {

    fun selectOpenPGP(protocol: SmartCardProtocol) {
        selectApplication(protocol, Base64.getDecoder().decode("0nYAASQB"))
    }

    fun timestampAndVersion(timestamp: Instant): ByteArray {
        val timestampBytes = intToBytes(timestamp.epochSecond.toInt())
        return byteArrayOf(0x04.toByte()) + timestampBytes
    }

    fun setGenerationTime(timestamp: Instant): ByteArray {
        return intToBytes(timestamp.epochSecond.toInt())
    }

    fun putData(protocol: SmartCardProtocol, command: Short, data: ByteArray): ByteArray {
        val bytes = shortToBytes(command)
        return protocol.sendAndReceive(Apdu(0x00, 0xDA, bytes[0].toInt(), bytes[1].toInt(), data))
    }

    fun mpi(encoded: ByteArray): ByteArray {
        val lengthBytes = shortToBytes(encoded.size.toShort())
        return lengthBytes + encoded
    }

    fun MutableList<Byte>.addAll(elements: ByteArray) {
        addAll(elements.toTypedArray())
    }
}