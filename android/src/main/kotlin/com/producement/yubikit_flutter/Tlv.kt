package com.producement.yubikit_flutter

data class Tlv(
    val tag: Int,
    val offset: Int,
    val length: Int,
    val end: Int,
) {
    companion object {
        fun parse(data: ByteArray, initialOffset: Int = 0): Tlv {
            var tag: Int = data[initialOffset].toInt()
            var offset = initialOffset + 1
            if (tag and 0x1F == 0x1F) {
                tag = tag shl 8 or data[offset].toInt()
                offset += 1;
                while (tag and 0x80 == 0x80) {
                    tag = tag shl 8 or data[offset].toInt()
                    offset += 1;
                }
            }
            var length = data[offset].toInt()
            offset += 1
            var end: Int

            if (length == 0x80) {
                end = offset;
                while (data[end].toInt() != 0x00 || data[end + 1].toInt() != 0x00) {
                    end = parse(data, end).end
                    length = end - offset
                    end += 2
                }
            } else {
                if (length > 0x80) {
                    val numberOfBytes = length - 0x80
                    length = bytesToInt(data.copyOfRange(offset, offset + numberOfBytes))
                    offset += numberOfBytes
                }
                end = offset + length
            }

            return Tlv(tag, offset, length, end)
        }

        private fun bytesToInt(bytes: ByteArray): Int {
            var result = 0
            for (i in bytes.indices) {
                result = result or (bytes[i].toInt() shl 8 * i)
            }
            return result
        }
    }
}

data class TlvData(
    val tlvData: Map<Int, Tlv>,
    val data: ByteArray
) {

    companion object {
        fun parse(data: ByteArray): TlvData {
            val parsedData = mutableMapOf<Int, Tlv>();
            var offset = 0;
            while (offset < data.size) {
                val tlv = Tlv.parse(data, offset)
                parsedData[tlv.tag] = tlv;
                offset = tlv.end;
            }
            return TlvData(parsedData, data);
        }
    }

    fun getValue(tag: Int): ByteArray {
        val tlv = tlvData[tag]
        if (tlv != null) {
            return data.copyOfRange(tlv.offset, tlv.end)
        }
        return ByteArray(0)
    }

    fun get(tag: Int): TlvData {
        return parse(getValue(tag))
    }

    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (javaClass != other?.javaClass) return false

        other as TlvData

        if (tlvData != other.tlvData) return false
        if (!data.contentEquals(other.data)) return false

        return true
    }

    override fun hashCode(): Int {
        var result = tlvData.hashCode()
        result = 31 * result + data.contentHashCode()
        return result
    }
}