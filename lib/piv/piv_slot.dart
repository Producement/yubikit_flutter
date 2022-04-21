enum YKFPIVSlot {
  authentication,
  signature,
  keyManagement,
  cardAuth,
  attestation,
}

extension YKFPIVSlotValue on YKFPIVSlot {
  int get value {
    switch (this) {
      case YKFPIVSlot.authentication:
        return 0x9a;
      case YKFPIVSlot.signature:
        return 0x9c;
      case YKFPIVSlot.keyManagement:
        return 0x9d;
      case YKFPIVSlot.cardAuth:
        return 0x9e;
      case YKFPIVSlot.attestation:
        return 0xf9;
    }
  }
}
