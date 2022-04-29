import 'dart:async';

import 'package:flutter/services.dart';

import 'piv/piv_session.dart';

class YubikitFlutter {
  static const MethodChannel _channel = MethodChannel('yubikit_flutter');

  static YubikitFlutterPivSession pivSession() {
    return YubikitFlutterPivSession(_channel);
  }
}
