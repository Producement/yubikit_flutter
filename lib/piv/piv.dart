import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:yubikit_flutter/piv/key_algorithm.dart';
import 'package:yubikit_flutter/piv/key_type.dart';
import 'package:yubikit_flutter/piv/management_key_type.dart';
import 'package:yubikit_flutter/piv/pin_policy.dart';
import 'package:yubikit_flutter/piv/touch_policy.dart';

import 'slot.dart';

class YubikitFlutterPiv {
  static const defaultPin = '123456';
  static const defaultPuk = '12345678';
  static const defaultManagementKey = [
    0x01,
    0x02,
    0x03,
    0x04,
    0x05,
    0x06,
    0x07,
    0x08,
    0x01,
    0x02,
    0x03,
    0x04,
    0x05,
    0x06,
    0x07,
    0x08,
    0x01,
    0x02,
    0x03,
    0x04,
    0x05,
    0x06,
    0x07,
    0x08
  ];

  static const MethodChannel _channel = MethodChannel('yubikit_flutter_piv');

  const YubikitFlutterPiv();

  Future<Uint8List> generateKey(
      YKFPIVSlot slot,
      YKFPIVKeyType type,
      YKFPIVPinPolicy pinPolicy,
      YKFPIVTouchPolicy touchPolicy,
      YKFPIVManagementKeyType managementKeyType,
      Uint8List managementKey,
      String pin) async {
    return await _channel.invokeMethod('pivGenerateKey', [
      slot.value,
      type.value,
      pinPolicy.value,
      touchPolicy.value,
      pin,
      managementKeyType.value,
      managementKey
    ]);
  }

  Future<Uint8List> signWithKey(YKFPIVSlot slot, YKFPIVKeyType type,
      YKFPIVKeyAlgorithm algorithm, String pin, Uint8List data) async {
    return await _channel.invokeMethod(
        'pivSignWithKey', [slot.value, type.value, algorithm.value, pin, data]);
  }

  Future<Uint8List> decryptWithKey(YKFPIVSlot slot,
      YKFPIVKeyAlgorithm algorithm, String pin, Uint8List encryptedData) async {
    return await _channel.invokeMethod(
        'pivDecryptWithKey', [slot.value, algorithm.value, pin, encryptedData]);
  }

  Future<Uint8List> encryptWithKey(
      YKFPIVKeyType type, Uint8List publicKey, Uint8List data) async {
    return await _channel
        .invokeMethod('pivEncryptWithKey', [type.value, publicKey, data]);
  }

  Future<void> reset() async {
    await _channel.invokeMethod('pivReset');
  }

  Future<int> getSerialNumber() async {
    return await _channel.invokeMethod('pivSerialNumber');
  }

  Future<void> setPin(String newPin, String oldPin) async {
    await _channel.invokeMethod('pivSetPin', [newPin, oldPin]);
  }

  Future<void> setPuk(String newPuk, String oldPuk) async {
    await _channel.invokeMethod('pivSetPuk', [newPuk, oldPuk]);
  }

  Future<Uint8List> getCertificate(YKFPIVSlot slot, String pin) async {
    return await _channel.invokeMethod('pivGetCertificate', [slot.value, pin]);
  }

  Future<Uint8List> putCertificate(
    YKFPIVSlot slot,
    String pin,
    Uint8List certificate,
    YKFPIVManagementKeyType managementKeyType,
    Uint8List managementKey,
  ) async {
    return await _channel.invokeMethod('pivPutCertificate',
        [slot.value, pin, certificate, managementKeyType.value, managementKey]);
  }

  Future<Uint8List> calculateSecretKey(
    YKFPIVSlot slot,
    String pin,
    Uint8List publicKey,
  ) async {
    return await _channel
        .invokeMethod('pivCalculateSecretKey', [slot.value, pin, publicKey]);
  }
}
