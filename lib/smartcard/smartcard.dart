import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:yubikit_flutter/yubikit_flutter.dart';

class YubikitFlutterSmartCard extends SmartCardInterface {
  static const MethodChannel _channel = MethodChannel('yubikit_flutter_sc');

  const YubikitFlutterSmartCard();

  @override
  Future<Stream<Uint8List>> sendCommands(
      Application application, List<List<int>> input,
      {List<int>? verify}) async {
    try {
      List<Object?> result = await _channel.invokeMethod('sendCommands', [
        input.map((e) => Uint8List.fromList(e)).toList(),
        application.value,
        Uint8List.fromList(verify ?? [])
      ]);
      return Stream.fromIterable(result.whereType<Uint8List>());
    } on PlatformException catch (e) {
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