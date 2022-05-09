import 'dart:typed_data';

enum KeySlot {
  signature,
  encryption,
  authentication,
}

extension KeySlotValues on KeySlot {
  String get value {
    switch (this) {
      case KeySlot.signature:
        return "SIGNATURE";
      case KeySlot.encryption:
        return "ENCRYPTION";
      case KeySlot.authentication:
        return "AUTHENTICATION";
    }
  }

  int get keyId {
    switch (this) {
      case KeySlot.signature:
        return 0xC1;
      case KeySlot.encryption:
        return 0xC2;
      case KeySlot.authentication:
        return 0xC3;
    }
  }

  int get fingerprint {
    switch (this) {
      case KeySlot.signature:
        return 0xC7;
      case KeySlot.encryption:
        return 0xC8;
      case KeySlot.authentication:
        return 0xC9;
    }
  }

  int get uif {
    switch (this) {
      case KeySlot.signature:
        return 0xD6;
      case KeySlot.encryption:
        return 0xD7;
      case KeySlot.authentication:
        return 0xD8;
    }
  }

  Uint8List get crt {
    switch (this) {
      case KeySlot.signature:
        return Uint8List.fromList([0xB6, 0x00]);
      case KeySlot.encryption:
        return Uint8List.fromList([0xB8, 0x00]);
      case KeySlot.authentication:
        return Uint8List.fromList([0xA4, 0x00]);
    }
  }
}
