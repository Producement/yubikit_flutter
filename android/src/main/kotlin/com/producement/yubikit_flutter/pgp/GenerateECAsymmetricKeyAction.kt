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

class GenerateECAsymmetricKeyAction : PGPAction() {
    companion object {
        private const val TAG = "GenerateECAction"
        fun generateECAsymmetricKeyIntent(
            context: Context,
            keyAttributesCommands: List<ByteArray>,
            generateAsymmetricKeyCommands: List<ByteArray>,
            curveParameters: List<ByteArray>,
            keySlots: List<Int>,
            genTimes: List<Int>,
            verify: ByteArray,
        ): Intent {
            Log.d(TAG, "Creating intent")
            val intent = YubiKeyPromptActivity.createIntent(
                context,
                GenerateECAsymmetricKeyAction::class.java
            )
            intent.putExtra("PGP_KEY_ATTRIBUTES", keyAttributesCommands.toTypedArray())
            intent.putExtra("PGP_GENERATE", generateAsymmetricKeyCommands.toTypedArray())
            intent.putExtra("PGP_CURVE_PARAMETERS", curveParameters.toTypedArray())
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
            val curveParameters = extras.getSerializable("PGP_CURVE_PARAMETERS") as Array<ByteArray>
            val keySlots = extras.getSerializable("PGP_KEY_SLOTS") as Array<Int>
            val genTimes = extras.getSerializable("PGP_GEN_TIMES") as Array<Int>
            val verify = extras.getByteArray("PGP_VERIFY")

            selectOpenPGP(protocol)
            verifyPin(verify, protocol)
            Log.d(TAG, "Generating #${keyAttributesCommands.size} keys")
            result((keyAttributesCommands.indices).map { i ->
                Log.d(TAG, "Generating EC key #$i")
                generateECKey(
                    protocol,
                    keyAttributesCommands[i],
                    generateCommands[i],
                    curveParameters[i],
                    keySlots[i],
                    genTimes[i]
                )
            })
        }
    }

    private fun generateECKey(
        protocol: SmartCardProtocol,
        keyAttributes: ByteArray,
        generate: ByteArray,
        curveParameters: ByteArray,
        keySlot: Int,
        genTime: Int
    ): ByteArray {
        Log.d(TAG, "Set key attributes")
        sendCommand(protocol, keyAttributes)
        Log.d(TAG, "Generating key")

        val response = sendCommand(protocol, generate)
        val publicKey = parsePublicKey(response)
        val timestamp = Instant.now()
        Log.d(TAG, "Setting fingerprint")

        putData(
            protocol,
            keySlot.toShort(),
            setECKeyFingerprint(publicKey, curveParameters, timestamp)
        )
        Log.d(TAG, "Setting generation time")
        putData(
            protocol,
            genTime.toShort(),
            setGenerationTime(timestamp)
        )
        Log.d(TAG, "Done!")
        return response
    }

    private fun setECKeyFingerprint(
        publicKey: ByteArray,
        curveParameters: ByteArray,
        timestamp: Instant
    ): ByteArray {
        val md = MessageDigest.getInstance("SHA-1")
        val encoded = mutableListOf<Byte>()
        encoded.addAll(timestampAndVersion(timestamp))
        encoded.addAll(curveParameters)
        encoded.addAll(keyMaterial(publicKey))
        val response = mutableListOf(0x99.toByte())
        response.addAll(mpi(encoded.toByteArray()))
        return md.digest(encoded.toByteArray())
    }

    private fun keyMaterial(publicKey: ByteArray): ByteArray {
        val length = publicKey.size * 8 - 1
        val lengthBytes = shortToBytes(length.toShort())
        return lengthBytes + publicKey
    }

    private fun parsePublicKey(response: ByteArray): ByteArray {
        val data = TlvData.parse(response).get(0x7F49)
        return data.getValue(0x86)
    }
}
