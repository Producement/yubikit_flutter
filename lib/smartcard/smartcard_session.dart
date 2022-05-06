import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:yubikit_flutter/smartcard/smartcard_application.dart';
import 'package:yubikit_flutter/smartcard/smartcard_instruction.dart';

class YubikitFlutterSmartCardSession {
  final MethodChannel _channel;

  YubikitFlutterSmartCardSession(this._channel);

  Future<Uint8List> sendCommand(Uint8List command,
      [Application? application]) async {
    if (application != null) {
      return await _channel
          .invokeMethod("smartCardCommand", [command, application.value]);
    } else {
      return await _channel.invokeMethod("smartCardCommand", [command]);
    }
  }

  Future<Uint8List> sendApdu(
      int cla, Instruction instruction, int p1, int p2, Uint8List data,
      [Application? application]) async {
    if (data.lengthInBytes > 0) {
      Uint8List command = Uint8List.fromList(
          [cla, instruction.value, p1, p2, data.lengthInBytes] + data);
      return sendCommand(
        command,
        application,
      );
    } else {
      Uint8List command = Uint8List.fromList([cla, instruction.value, p1, p2]);
      return sendCommand(command, application);
    }
  }
}
