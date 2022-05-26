import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:yubikit_openpgp/smartcard/application.dart';
import 'package:yubikit_openpgp/smartcard/interface.dart';

class YubikitFlutterSmartCard extends SmartCardInterface {
  static const MethodChannel _channel = MethodChannel('yubikit_flutter_sc');

  const YubikitFlutterSmartCard();

  @override
  Future<Uint8List> sendCommand(Application application, List<int> input,
      {List<int>? verify}) async {
    return await _channel.invokeMethod('sendCommand',
        [input, application.value, Uint8List.fromList(verify ?? [])]);
  }
}
