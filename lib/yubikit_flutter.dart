import 'package:yubikit_flutter/openpgp/session.dart';
import 'package:yubikit_flutter/smartcard/session.dart';

import 'piv/session.dart';

class YubikitFlutter {
  static YubikitFlutterPivSession pivSession() {
    return YubikitFlutterPivSession();
  }

  static YubikitFlutterSmartCardSession smartCardSession() {
    return YubikitFlutterSmartCardSession();
  }

  static YubikitFlutterOpenPGPSession openPGPSession() {
    return YubikitFlutterOpenPGPSession(smartCardSession());
  }
}
