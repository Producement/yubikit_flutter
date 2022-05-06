import 'package:flutter/services.dart';
import 'package:yubikit_flutter/smartcard/smartcard_session.dart';

import 'piv/piv_session.dart';

class YubikitFlutter {
  static const MethodChannel _channel = MethodChannel('yubikit_flutter');

  static YubikitFlutterPivSession pivSession() {
    return YubikitFlutterPivSession(_channel);
  }

  static YubikitFlutterSmartCardSession smartCardSession() {
    return YubikitFlutterSmartCardSession(_channel);
  }
}
