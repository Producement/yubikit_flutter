import 'dart:typed_data';
import 'package:convert/convert.dart';

enum Application {
  otp,
  management,
  openpgp,
  oath,
  piv,
  fido,
  hsmauth,
}

extension ApplicationValue on Application {
  Uint8List get value {
    switch (this) {
      case Application.otp:
        return Uint8List.fromList(hex.decode("a0000005272001"));
      case Application.management:
        return Uint8List.fromList(hex.decode("a000000527471117"));
      case Application.openpgp:
        return Uint8List.fromList(hex.decode("d27600012401"));
      case Application.oath:
        return Uint8List.fromList(hex.decode("a0000005272101"));
      case Application.piv:
        return Uint8List.fromList(hex.decode("a000000308"));
      case Application.fido:
        return Uint8List.fromList(hex.decode("a0000006472f0001"));
      case Application.hsmauth:
        return Uint8List.fromList(hex.decode("a000000527210701"));
    }
  }
}
