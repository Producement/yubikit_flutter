import 'dart:typed_data';

enum TouchMode {
  off,
  on,
  fixed,
  cached,
  cachedFixed,
}

extension TouchModeValues on TouchMode {
  static TouchMode parse(Uint8List data) {
    late TouchMode actualMode;
    for (TouchMode mode in TouchMode.values) {
      if (mode.value == data[0]) {
        actualMode = mode;
        break;
      }
    }
    return actualMode;
  }

  int get value {
    switch (this) {
      case TouchMode.off:
        return 0x00;
      case TouchMode.on:
        return 0x01;
      case TouchMode.fixed:
        return 0x02;
      case TouchMode.cached:
        return 0x03;
      case TouchMode.cachedFixed:
        return 0x04;
    }
  }
}
