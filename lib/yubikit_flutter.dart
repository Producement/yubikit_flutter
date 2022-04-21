import 'dart:async';

import 'package:flutter/services.dart';

import 'piv/piv_session.dart';

class YubikitFlutter {
  static const MethodChannel _channel = MethodChannel('yubikit_flutter');

  static Future<YubikitFlutter> connect() async {
    await _channel.invokeMethod("connect");
    return YubikitFlutter();
  }

  Future<void> disconnect() async {
    await _channel.invokeMethod("disconnect");
  }

  YubikitFlutterPivSession pivSession() {
    return YubikitFlutterPivSession(_channel);
  }
}
