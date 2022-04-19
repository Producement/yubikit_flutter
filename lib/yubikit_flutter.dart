// You have generated a new plugin project without
// specifying the `--platforms` flag. A plugin project supports no platforms is generated.
// To add platforms, run `flutter create -t plugin --platforms <platforms> .` under the same
// directory. You can also find a detailed instruction on how to add platforms in the `pubspec.yaml` at https://flutter.dev/docs/development/packages-and-plugins/developing-packages#plugin-platforms.

import 'dart:async';

import 'package:flutter/services.dart';
import 'package:logger/logger.dart';

class YubikitFlutter {
  static Logger logger = Logger();
  static const MethodChannel _channel = MethodChannel('yubikit_flutter');

  static Future<String?> get platformVersion async {
    final String? version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  static Future<void> reset() async {
    logger.d("Reset PIV called");
    dynamic result = await _channel.invokeMethod("resetPiv");
    if (result != null) {
      logger.e(result);
    }
  }

  static Future<void> connect() async {
    logger.d("Connect called");
    dynamic result = await _channel.invokeMethod("connect");
    if (result != null) {
      logger.e(result);
    }
  }

  static Future<void> disconnect() async {
    dynamic result =  await _channel.invokeMethod("disconnect");
    if (result != null) {
      logger.e(result);
    }
  }

  static Future<void> verifyPin(String pin) async {
    logger.d("Verify PIV called");
    dynamic result =  await _channel.invokeMethod("verifyPin", pin);
    if (result != null) {
      logger.e(result);
    }
  }
}
