package com.producement.yubikit_flutter

import org.assertj.core.api.Assertions.assertThat
import org.junit.jupiter.api.Test

class TlvTest {
    @Test
    fun `Parses simple TLV value`() {
        val data = byteArrayOf(0x60, 0x02, 0x01, 0x03)
        val tlv = Tlv.parse(data)
        assertThat(tlv.tag).isEqualTo(0x60)
        assertThat(tlv.offset).isEqualTo(0x02)
        assertThat(tlv.end).isEqualTo(0x04)
        assertThat(tlv.length).isEqualTo(0x02)
    }

    @Test
    fun `Parses simple TLV data value as map`() {
        val data = byteArrayOf(0x60, 0x02, 0x01, 0x03)
        val tlvData = TlvData.parse(data)
        assertThat(tlvData.getValue(0x60)).isEqualTo(byteArrayOf(0x01, 0x03))
    }

    @Test
    fun `Parses multiple TLV values`() {
        val data = byteArrayOf(0x60, 0x02, 0x01, 0x03, 0x61, 0x01, 0x01, 0x62, 0x00)
        val tlvData = TlvData.parse(data)
        assertThat(tlvData.getValue(0x60)).isEqualTo(byteArrayOf(0x01, 0x03))
        assertThat(tlvData.getValue(0x61)).isEqualTo(byteArrayOf(0x01))
        assertThat(tlvData.getValue(0x62)).isEqualTo(byteArrayOf())
    }

    @Test
    fun `Handles multi byte tags`() {
        val data =
            byteArrayOf(0x7f, 0x49, 0x09, 0x60, 0x02, 0x01, 0x03, 0x61, 0x01, 0x01, 0x62, 0x00)
        val tlvData = TlvData.parse(data).get(0x7f49)
        assertThat(tlvData.data).isEqualTo(
            byteArrayOf(
                0x60,
                0x02,
                0x01,
                0x03,
                0x61,
                0x01,
                0x01,
                0x62,
                0x00
            )
        )
        assertThat(tlvData.getValue(0x60)).isEqualTo(byteArrayOf(0x01, 0x03))
        assertThat(tlvData.getValue(0x61)).isEqualTo(byteArrayOf(0x01))
        assertThat(tlvData.getValue(0x62)).isEqualTo(byteArrayOf())
    }
}