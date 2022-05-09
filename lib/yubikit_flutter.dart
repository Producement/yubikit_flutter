import 'package:flutter/services.dart';
import 'package:yubikit_flutter/openpgp/session.dart';
import 'package:yubikit_flutter/smartcard/session.dart';

import 'piv/piv_session.dart';

class YubikitFlutter {
  static const MethodChannel _channel = MethodChannel('yubikit_flutter');

  YubikitFlutter();

  factory YubikitFlutter.connect() {
    return YubikitFlutter()..start();
  }

  Future<void> start() async {
    await _channel.invokeMethod("start");
  }

  Future<void> stop() async {
    await _channel.invokeMethod("stop");
  }

  YubikitFlutterPivSession pivSession() {
    return YubikitFlutterPivSession(_channel);
  }

  YubikitFlutterSmartCardSession smartCardSession() {
    return YubikitFlutterSmartCardSession(_channel);
  }

  YubikitFlutterOpenPGPSession openPGPSession() {
    return YubikitFlutterOpenPGPSession(smartCardSession());
  }
}
