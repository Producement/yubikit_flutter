import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:yubikit_flutter/smartcard/application.dart';
import 'package:yubikit_flutter/smartcard/instruction.dart';

class YubikitFlutterSmartCardSession {
  final MethodChannel _channel;

  YubikitFlutterSmartCardSession(this._channel);

  Future<Uint8List> sendCommand(Uint8List command) async {
    return await _channel.invokeMethod("smartCardCommand", [command]);
  }

  Future<void> selectApplication(Application application) async {
    return await _channel
        .invokeMethod("smartCardSelectApplication", [application.value]);
  }

  Future<Uint8List> sendApdu(
      int cla, Instruction instruction, int p1, int p2, Uint8List data) async {
    if (data.lengthInBytes > 0) {
      Uint8List command = Uint8List.fromList(
          [cla, instruction.value, p1, p2, data.lengthInBytes] + data);
      return sendCommand(
        command,
      );
    } else {
      Uint8List command = Uint8List.fromList([cla, instruction.value, p1, p2]);
      return sendCommand(command);
    }
  }
}
