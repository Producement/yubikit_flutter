enum YKFPIVTouchPolicy {
  def,
  never,
  always,
  cached,
}

extension YKFPIVTouchPolicyValue on YKFPIVTouchPolicy {
  int get value {
    switch (this) {
      case YKFPIVTouchPolicy.def:
        return 0x0;
      case YKFPIVTouchPolicy.never:
        return 0x1;
      case YKFPIVTouchPolicy.always:
        return 0x2;
      case YKFPIVTouchPolicy.cached:
        return 0x3;
    }
  }
}
