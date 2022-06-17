import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:yubikit_flutter/yubikit_flutter.dart';

class YubikitFlutterSmartCard extends SmartCardInterface {
  static const MethodChannel _channel = MethodChannel('yubikit_flutter_sc');

  const YubikitFlutterSmartCard();

  @override
  Future<Stream<SmartCardResponse>> sendCommands(
      Application application, List<List<int>> input,
      {List<int>? verify}) async {
    try {
      List<Object?> result = await _channel.invokeMethod('sendCommands', [
        input.map((e) => Uint8List.fromList(e)).toList(),
        application.value,
        Uint8List.fromList(verify ?? [])
      ]);
      final responses = result
          .whereType<Uint8List>()
          .map((e) => SmartCardResponse.fromBytes(e));
      return Stream.fromIterable(responses);
    } on PlatformException catch (e) {
      if (e.message == 'Tag was lost.' || e.message == 'Tag connection lost') {
        throw TagLostException();
      }
      if (e.code == 'yubikit.smartcard.error') {
        int sws = e.details;
        final data = ByteData(2)..setUint16(0, sws);
        throw SmartCardException(data.getUint8(0), data.getUint8(1));
      } else {
        rethrow;
      }
    }
  }
}

class TagLostException implements Exception {}
