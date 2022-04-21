import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:yubikit_flutter/piv/piv_key_algorithm.dart';
import 'package:yubikit_flutter/piv/piv_key_type.dart';

import 'piv_slot.dart';

class YubikitFlutterPivSession {
  final MethodChannel _channel;

  YubikitFlutterPivSession(this._channel);

  Future<Uint8List> generateKey(
      YKFPIVSlot slot, YKFPIVKeyType type, String pin) async {
    dynamic signature = await _channel
        .invokeMethod("pivGenerateKey", [slot.value, type.value, pin]);
    return signature as Uint8List;
  }

  Future<Uint8List> signWithKey(YKFPIVSlot slot, YKFPIVKeyType type,
      YKFPIVKeyAlgorithm algorithm, String pin, Uint8List data) async {
    dynamic signature = await _channel.invokeMethod(
        "pivSignWithKey", [slot.value, type.value, algorithm.value, pin, data]);
    return signature as Uint8List;
  }

  Future<Uint8List> decryptWithKey(YKFPIVSlot slot,
      YKFPIVKeyAlgorithm algorithm, String pin, Uint8List encryptedData) async {
    dynamic decryptedData = await _channel.invokeMethod(
        "pivDecryptWithKey", [slot.value, algorithm.value, pin, encryptedData]);
    return decryptedData as Uint8List;
  }

  Future<Uint8List> getPublicKey(YKFPIVSlot slot) async {
    dynamic publicKey =
        await _channel.invokeMethod("pivGetPublicKey", [slot.value]);
    return publicKey as Uint8List;
  }
}
