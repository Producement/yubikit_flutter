import 'package:convert/convert.dart';
import 'package:test/test.dart';
import 'package:yubikit_flutter/openpgp/curve.dart';
import 'package:yubikit_flutter/openpgp/fingerprint.dart';

void main() {
  test("calculates fingerprint", () async {
    var pubKey =
        "40189452D84165788AE29A0CD494D2C7C01EECA5333B5426FEF6D52CD206C91AAE";
    var fingerprint = FingerprintCalculator.calculateFingerprint(
        BigInt.parse(pubKey, radix: 16), ECCurve.ed25519, 1652084583);
    expect(hex.encode(fingerprint),
        equals("D25515C366D77B8E9B66CD4BAC6B363B0C5A4FBD".toLowerCase()));
  });
}
