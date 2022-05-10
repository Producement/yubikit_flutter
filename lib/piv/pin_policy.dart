enum YKFPIVPinPolicy { def, never, once, always }

extension YKFPIVPinPolicyValue on YKFPIVPinPolicy {
  int get value {
    switch (this) {
      case YKFPIVPinPolicy.def:
        return 0x0;
      case YKFPIVPinPolicy.never:
        return 0x1;
      case YKFPIVPinPolicy.once:
        return 0x2;
      case YKFPIVPinPolicy.always:
        return 0x3;
    }
  }
}
