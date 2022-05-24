import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:yubikit_openpgp/smartcard/application.dart';
import 'package:yubikit_openpgp/smartcard/interface.dart';

class YubikitFlutterSmartCardSession extends SmartCardInterface {
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

  @override
  Future<Uint8List> sendCommand(List<int> input) async {
    return await _channel.invokeMethod("sendCommand", [input]);
  }

  Future<void> selectApplication(Application application) async {
    return await _channel
        .invokeMethod("selectApplication", [application.value]);
  }
}
