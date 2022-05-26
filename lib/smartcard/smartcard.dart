import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:yubikit_openpgp/smartcard/application.dart';

class YubikitFlutterSmartCard {
  static const MethodChannel _channel = MethodChannel('yubikit_flutter_sc');

  const YubikitFlutterSmartCard();

  Future<Uint8List> sendCommand(
      Application application, List<int> input) async {
    return await _channel
        .invokeMethod('sendCommand', [input, application.value]);
  }
}
