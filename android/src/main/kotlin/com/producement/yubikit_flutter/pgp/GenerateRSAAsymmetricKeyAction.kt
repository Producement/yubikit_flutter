package com.producement.yubikit_flutter.pgp

import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.util.Log
import com.producement.yubikit_flutter.TlvData
import com.yubico.yubikit.android.ui.YubiKeyPromptActivity
import com.yubico.yubikit.core.application.CommandState
import com.yubico.yubikit.core.smartcard.SmartCardConnection
import com.yubico.yubikit.core.smartcard.SmartCardProtocol
import com.yubico.yubikit.core.util.Pair
import java.security.MessageDigest
import java.time.Instant

class GenerateRSAAsymmetricKeyAction : PGPAction() {
    companion object {
        private const val TAG = "GenerateRSAAction"
        fun generateRSAAsymmetricKeyIntent(
            context: Context,
            keyAttributesCommands: List<ByteArray>,
            generateAsymmetricKeyCommands: List<ByteArray>,
            keySlots: List<Int>,
            genTimes: List<Int>,
            verify: ByteArray,
        ): Intent {
            Log.d(TAG, "Creating intent")
            val intent = YubiKeyPromptActivity.createIntent(
                context,
                GenerateRSAAsymmetricKeyAction::class.java
            )
            intent.putExtra("PGP_KEY_ATTRIBUTES", keyAttributesCommands.toTypedArray())
            intent.putExtra("PGP_GENERATE", generateAsymmetricKeyCommands.toTypedArray())
            intent.putExtra("PGP_KEY_SLOTS", keySlots.toTypedArray())
            intent.putExtra("PGP_GEN_TIMES", genTimes.toTypedArray())
            intent.putExtra("PGP_VERIFY", verify)
            return intent
        }
    }

    override fun onYubiKeyConnection(
        connection: SmartCardConnection,
        extras: Bundle,
        commandState: CommandState
    ): Pair<Int, Intent> {
        return tryWithCommand(commandState) {
            Log.d(TAG, "Starting Yubikey connection")
            val protocol = SmartCardProtocol(connection)
            val keyAttributesCommands =
                extras.getSerializable("PGP_KEY_ATTRIBUTES") as Array<ByteArray>
            val generateCommands = extras.getSerializable("PGP_GENERATE") as Array<ByteArray>
            val keySlots = extras.getSerializable("PGP_KEY_SLOTS") as Array<Int>
            val genTimes = extras.getSerializable("PGP_GEN_TIMES") as Array<Int>
            val verify = extras.getByteArray("PGP_VERIFY")

            selectOpenPGP(protocol)
            verifyPin(verify, protocol)
            Log.d(TAG, "Generating #${keyAttributesCommands.size} keys")
            result((keyAttributesCommands.indices).map { i ->
                Log.d(TAG, "Generating RSA key #$i")
                generateRSAKey(
                    protocol,
                    keyAttributesCommands[i],
                    generateCommands[i],
                    keySlots[i],
                    genTimes[i]
                )
            })
        }
    }

    private fun generateRSAKey(
        protocol: SmartCardProtocol,
        keyAttributes: ByteArray,
        generate: ByteArray,
        keySlot: Int,
        genTime: Int
    ): ByteArray {
        sendCommand(protocol, keyAttributes)
        val response = sendCommand(protocol, generate)
        val (modulus, exponent) = parsePublicKey(response)
        val timestamp = Instant.now()
        putData(
            protocol,
            keySlot.toShort(),
            setRSAKeyFingerprint(modulus, exponent, timestamp)
        )
        putData(
            protocol,
            genTime.toShort(),
            setGenerationTime(timestamp)
        )
        return response
    }

    private fun setRSAKeyFingerprint(
        modulus: ByteArray,
        exponent: ByteArray,
        timestamp: Instant
    ): ByteArray {
        val md = MessageDigest.getInstance("SHA-1")
        val encoded = mutableListOf<Byte>()
        encoded.addAll(timestampAndVersion(timestamp))
        encoded.addAll(mpi(modulus))
        encoded.addAll(mpi(exponent))
        val response = mutableListOf(0x99.toByte())
        response.addAll(mpi(encoded.toByteArray()))
        return md.digest(encoded.toByteArray())
    }

    private fun parsePublicKey(response: ByteArray): kotlin.Pair<ByteArray, ByteArray> {
        val data = TlvData.parse(response).get(0x7F49)
        val modulus = data.getValue(0x81)
        val exponent = data.getValue(0x82)
        return modulus to exponent
    }
}