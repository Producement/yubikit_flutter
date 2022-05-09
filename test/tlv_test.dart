import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:yubikit_flutter/openpgp/tlv.dart';

void main() {
  test("Parses simple TLV value", () async {
    Uint8List data = Uint8List.fromList([0x60, 0x02, 0x01, 0x03]);
    Tlv tlv = Tlv.parse(data, offset: 0);
    expect(tlv.tag, equals(0x60));
    expect(tlv.offset, equals(0x02));
    expect(tlv.end, equals(0x04));
    expect(tlv.length, equals(0x02));
  });

  test("Parses simple TLV data value as map", () async {
    Uint8List data = Uint8List.fromList([0x60, 0x02, 0x01, 0x03]);
    TlvData tlvData = TlvData.parse(data);
    expect(tlvData.get(0x60), equals(Uint8List.fromList([0x01, 0x03])));
  });

  test("Parses multiple TLV values", () async {
    Uint8List data = Uint8List.fromList(
        [0x60, 0x02, 0x01, 0x03, 0x61, 0x01, 0x01, 0x62, 0x00]);
    TlvData tlvData = TlvData.parse(data);
    expect(tlvData.get(0x60), equals(Uint8List.fromList([0x01, 0x03])));
    expect(tlvData.get(0x61), equals(Uint8List.fromList([0x01])));
    expect(tlvData.get(0x62), equals(Uint8List.fromList([])));
  });
}
