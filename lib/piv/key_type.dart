enum YKFPIVKeyType {
  rsa1024,
  rsa2048,
  eccp256,
  eccp384,
}

extension YKFPIVKeyTypeValue on YKFPIVKeyType {
  int get value {
    switch (this) {
      case YKFPIVKeyType.rsa1024:
        return 0x06;
      case YKFPIVKeyType.rsa2048:
        return 0x07;
      case YKFPIVKeyType.eccp256:
        return 0x11;
      case YKFPIVKeyType.eccp384:
        return 0x14;
    }
  }
}
