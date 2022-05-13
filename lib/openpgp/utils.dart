import 'dart:convert';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';

import 'curve.dart';

class PGPUtils {
  static List<int> calculateFingerprint(BigInt publicKey, ECCurve curve,
      [int? timestamp]) {
    return sha1
        .convert(buildPublicKeyPacket(publicKey, curve, timestamp, 0x99))
        .bytes;
  }

  static List<int> buildPublicKeyPacket(BigInt publicKey, ECCurve curve,
      [int? timestamp, int? type]) {
    List<int> encoded =
        _timestampAndVersion() + _curve(curve) + _keyMaterial(publicKey);
    type ??= encoded.length >> 8 == 0 ? 0x98 : 0x99;
    var lengthEncoded = type == 0x98
        ? [type, encoded.length]
        : [type, encoded.length >> 8, encoded.length];
    return lengthEncoded + encoded;
  }

  static List<int> buildSecretKeyPacket(BigInt secretKey, ECCurve curve,
      [int? timestamp, int? type]) {
    List<int> encoded =
        _timestampAndVersion() + _curve(curve) + _keyMaterial(secretKey);
    type ??= encoded.length >> 8 == 0 ? 0x98 : 0x99;
    var lengthEncoded = type == 0x98
        ? [type, encoded.length]
        : [type, encoded.length >> 8, encoded.length];
    return lengthEncoded + encoded;
  }

  static List<int> _timestampAndVersion([int version = 0x04, int? timestamp]) {
    timestamp ??= (DateTime.now().millisecondsSinceEpoch / 1000).round();
    var timestampBytes = ByteData(4)..setInt32(0, timestamp);
    return [version] + timestampBytes.buffer.asUint8List();
  }

  static List<int> _curve(ECCurve curve) {
    return [curve.algorithm, curve.oid.length] + curve.oid;
  }

  static List<int> _keyMaterial(BigInt key) {
    return Uint8List.fromList([key.bitLength >> 8, key.bitLength]) +
        _bigIntToUint8List(key);
  }

  static String armor(List<int> packet) {
    var content = base64Encode(packet);
    return '''-----BEGIN PGP PUBLIC KEY BLOCK-----

$content
=${base64Encode(crc24(packet))}
-----END PGP PUBLIC KEY BLOCK-----''';
  }

  static List<int> crc24(List<int> octets) {
    int crc = 0xB704CE;
    for (var octet in octets) {
      crc ^= octet << 16;
      for (var i = 0; i < 8; i++) {
        crc <<= 1;
        if (crc & 0x1000000 != 0) {
          crc ^= 0x1864CFB;
        }
      }
    }
    return (ByteData(4)..setUint32(0, crc & 0xFFFFFF)).buffer.asUint8List(1);
  }

  static Uint8List _bigIntToUint8List(BigInt bigInt) =>
      _bigIntToByteData(bigInt).buffer.asUint8List();

  static ByteData _bigIntToByteData(BigInt bigInt) {
    final data = ByteData((bigInt.bitLength / 8).ceil());
    var _bigInt = bigInt;

    for (var i = 1; i <= data.lengthInBytes; i++) {
      data.setUint8(data.lengthInBytes - i, _bigInt.toUnsigned(8).toInt());
      _bigInt = _bigInt >> 8;
    }

    return data;
  }
}
