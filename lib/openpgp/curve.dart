import 'dart:typed_data';

import 'package:pointycastle/asn1.dart';

enum ECCurve {
  secp256r1,
  secp256k1,
  secp384r1,
  secp521r1,
  brainpoolp256r1,
  brainpoolp384r1,
  brainpoolp512r1,
  x25519,
  ed25519,
}

extension ECCurveValues on ECCurve {
  Uint8List get oid {
    switch (this) {
      case ECCurve.secp256r1:
        return Uint8List.fromList(
            [0x2a, 0x86, 0x48, 0xce, 0x3d, 0x03, 0x01, 0x07]);
      case ECCurve.secp256k1:
        return Uint8List.fromList([0x2b, 0x81, 0x04, 0x00, 0x0a]);
      case ECCurve.secp384r1:
        return Uint8List.fromList([0x2b, 0x81, 0x04, 0x00, 0x22]);
      case ECCurve.secp521r1:
        return Uint8List.fromList([0x2b, 0x81, 0x04, 0x00, 0x23]);
      case ECCurve.brainpoolp256r1:
        return Uint8List.fromList(
            [0x2b, 0x24, 0x03, 0x03, 0x02, 0x08, 0x01, 0x01, 0x07]);
      case ECCurve.brainpoolp384r1:
        return Uint8List.fromList(
            [0x2b, 0x24, 0x03, 0x03, 0x02, 0x08, 0x01, 0x01, 0x0b]);
      case ECCurve.brainpoolp512r1:
        return Uint8List.fromList(
            [0x2b, 0x24, 0x03, 0x03, 0x02, 0x08, 0x01, 0x01, 0x0d]);
      case ECCurve.x25519:
        return Uint8List.fromList(
            [0x2b, 0x06, 0x01, 0x04, 0x01, 0x97, 0x55, 0x01, 0x05, 0x01]);
      case ECCurve.ed25519:
        return Uint8List.fromList(
            [0x2b, 0x06, 0x01, 0x04, 0x01, 0xda, 0x47, 0x0f, 0x01]);
    }
  }

  int get algorithm {
    switch (this) {
      case ECCurve.secp256r1:
        return 19;
      case ECCurve.secp256k1:
        return 19;
      case ECCurve.secp384r1:
        return 19;
      case ECCurve.secp521r1:
        return 19;
      case ECCurve.brainpoolp256r1:
        return 19;
      case ECCurve.brainpoolp384r1:
        return 19;
      case ECCurve.brainpoolp512r1:
        return 19;
      case ECCurve.x25519:
        return 19;
      case ECCurve.ed25519:
        return 22;
    }
  }

  ASN1ObjectIdentifier get identifier {
    switch (this) {
      case ECCurve.secp256k1:
        return ASN1ObjectIdentifier([1, 2, 840, 10045, 3, 1, 7]);
      case ECCurve.secp256r1:
        return ASN1ObjectIdentifier([1, 3, 132, 0, 10]);
      case ECCurve.secp384r1:
        return ASN1ObjectIdentifier([1, 3, 132, 0, 34]);
      case ECCurve.secp521r1:
        return ASN1ObjectIdentifier([1, 3, 132, 0, 35]);
      case ECCurve.ed25519:
        return ASN1ObjectIdentifier([1, 3, 6, 1, 4, 1, 11591, 15, 1]);
      case ECCurve.x25519:
        return ASN1ObjectIdentifier([1, 3, 6, 1, 4, 1, 3029, 1, 5, 1]);
      case ECCurve.brainpoolp256r1:
        return ASN1ObjectIdentifier([1, 3, 36, 3, 3, 2, 8, 1, 1, 5]);
      case ECCurve.brainpoolp384r1:
        return ASN1ObjectIdentifier([1, 3, 36, 3, 3, 2, 8, 1, 1, 11]);
      case ECCurve.brainpoolp512r1:
        return ASN1ObjectIdentifier([1, 3, 36, 3, 3, 2, 8, 1, 1, 13]);
    }
  }
}
