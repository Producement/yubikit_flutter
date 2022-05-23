import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:yubikit_openpgp/smartcard/application.dart';
import 'package:yubikit_openpgp/smartcard/instruction.dart';

class YubikitFlutterSmartCardSession {
  static const MethodChannel _channel = MethodChannel('yubikit_flutter_sc');

  const YubikitFlutterSmartCardSession();

  Future<T> doInSession<T>(Future<T> Function() action) async {
    try {
      await start();
      return await action();
    } finally {
      await stop();
    }
  }

  Future<T> doWithApplication<T>(
      Application application, Future<T> Function() action) async {
    return doInSession(() async {
      await selectApplication(application);
      return await action();
    });
  }

  Future<void> start() async {
    await _channel.invokeMethod("start");
  }

  Future<void> stop() async {
    await _channel.invokeMethod("stop");
  }

  Future<Uint8List> sendCommand(Uint8List command) async {
    return await _channel.invokeMethod("sendCommand", [command]);
  }

  Future<void> selectApplication(Application application) async {
    return await _channel
        .invokeMethod("selectApplication", [application.value]);
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