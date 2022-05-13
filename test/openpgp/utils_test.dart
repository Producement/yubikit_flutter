import 'dart:convert';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:test/test.dart';
import 'package:yubikit_flutter/openpgp/curve.dart';
import 'package:yubikit_flutter/openpgp/utils.dart';

Uint8List _bigIntToUint8List(BigInt bigInt) =>
    _bigIntToByteData(bigInt).buffer.asUint8List();

ByteData _bigIntToByteData(BigInt bigInt) {
  final data = ByteData((bigInt.bitLength / 8).ceil());
  var _bigInt = bigInt;

  for (var i = 1; i <= data.lengthInBytes; i++) {
    data.setUint8(data.lengthInBytes - i, _bigInt.toUnsigned(8).toInt());
    _bigInt = _bigInt >> 8;
  }

  return data;
}

void main() {
  test("calculates fingerprint", () async {
    var pubKey =
        "40189452D84165788AE29A0CD494D2C7C01EECA5333B5426FEF6D52CD206C91AAE";
    var fingerprint = PGPUtils.calculateFingerprint(
        BigInt.parse(pubKey, radix: 16), ECCurve.ed25519, 1652084583);
    print(_bigIntToUint8List(BigInt.parse(
        "7480317426394696936448527343812174929534157707887635210617056164323067967739714")));
    expect(hex.encode(fingerprint),
        equals("D25515C366D77B8E9B66CD4BAC6B363B0C5A4FBD".toLowerCase()));
  });

  test("builds PGP public key packet", () async {
    var pubKeyAsBigInt = BigInt.parse(
        "7421333061992363374626259639439359738434221499360902310111361495942986672053976");

    var timestamp =
        (DateTime.parse("2022-05-05T16:13:58+03:00").millisecondsSinceEpoch /
                1000)
            .round();
    expect(
        PGPUtils.buildPublicKeyPacket(
            pubKeyAsBigInt, ECCurve.ed25519, timestamp),
        equals(hex.decode(
            "9833046273cd9616092b06010401da470f010107401785a8be6b7d9bfe092e3a1172386c98a498298a44644fbd90ae8fb9c6d31ed8")));
  });

  test("armor", () async {
    final result = PGPUtils.armor(base64.decode(
        "yDgBO22WxBHv7O8X7O/jygAEzol56iUKiXmV+XmpCtmpqQUKiQrFqclFqUDBovzSvBSFjNSiVHsuAA=="));
    expect(result, equals('''-----BEGIN PGP PUBLIC KEY BLOCK-----

yDgBO22WxBHv7O8X7O/jygAEzol56iUKiXmV+XmpCtmpqQUKiQrFqclFqUDBovzSvBSFjNSiVHsuAA==
=njUN
-----END PGP PUBLIC KEY BLOCK-----'''));
  });
}
