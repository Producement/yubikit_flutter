import 'dart:typed_data';

import 'package:crypto/crypto.dart';

import 'curve.dart';

class FingerprintCalculator {
  static List<int> calculateFingerprint(BigInt publicKey, ECCurve curve,
      [int? timestamp]) {
    timestamp ??= DateTime.now().millisecondsSinceEpoch;
    var timestampBytes = ByteData(4)..setInt32(0, timestamp);
    int version = 4;
    var asn1 = curve.identifier..encode();
    List<int> encoded = [version] +
        timestampBytes.buffer.asInt8List() +
        [curve.algorithm, asn1.valueBytes!.length] +
        Int8List.fromList(asn1.valueBytes!) +
        [publicKey.bitLength >> 8, publicKey.bitLength] +
        bigIntToUint8List(publicKey);
    List<int> data = [0x99, encoded.length >> 8, encoded.length] + encoded;
    return sha1.convert(data).bytes;
  }

  static Uint8List bigIntToUint8List(BigInt bigInt) =>
      bigIntToByteData(bigInt).buffer.asUint8List();

  static ByteData bigIntToByteData(BigInt bigInt) {
    final data = ByteData((bigInt.bitLength / 8).ceil());
    var _bigInt = bigInt;

    for (var i = 1; i <= data.lengthInBytes; i++) {
      data.setUint8(data.lengthInBytes - i, _bigInt.toUnsigned(8).toInt());
      _bigInt = _bigInt >> 8;
    }

    return data;
  }
}
