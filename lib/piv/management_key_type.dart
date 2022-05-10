enum YKFPIVManagementKeyType {
  tripleDES,
  aes128,
  aes192,
  aes256,
}

extension YKFPIVManagementKeyTypeValue on YKFPIVManagementKeyType {
  int get value {
    switch (this) {
      case YKFPIVManagementKeyType.tripleDES:
        return 0x03;
      case YKFPIVManagementKeyType.aes128:
        return 0x08;
      case YKFPIVManagementKeyType.aes192:
        return 0x0a;
      case YKFPIVManagementKeyType.aes256:
        return 0x0c;
    }
  }
}
