import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:flutter/services.dart';
import 'package:yubikit_flutter/yubikit_flutter.dart';

class YubikitOpenPGPBatch {
  static const MethodChannel _channel = MethodChannel('yubikit_flutter_pgp');
  final YubikitOpenPGPCommands _commands;
  final PinProvider _pinProvider;

  const YubikitOpenPGPBatch(this._commands, this._pinProvider);

  Future<Map<KeySlot, ECKeyData>> generateECKeys(
      Map<KeySlot, ECCurve> slots) async {
    final generateResponses = await sendCommands(
        'generateECAsymmetricKey',
        [
          ecKeyAttributes(slots),
          generate(slots.keys),
          ecCurveParams(slots.values)
        ],
        [
          slots.keys.map((e) => e.fingerprint).toList(),
          slots.keys.map((e) => e.genTime).toList(),
        ],
        verify: _commands.verifyAdminPin(_pinProvider.adminPin));
    return Map.fromEntries(generateResponses.mapIndexed((i, generateResponse) {
      if (generateResponse is SuccessfulResponse) {
        final keySlot = slots.keys.elementAt(i);
        return MapEntry(
            keySlot, ECKeyData.fromBytes(generateResponse.response, keySlot));
      } else if (generateResponse is ErrorResponse) {
        throw generateResponse.exception;
      }
      throw Exception('Invalid response type ${generateResponse.runtimeType}');
    }));
  }

  List<List<int>> ecKeyAttributes(Map<KeySlot, ECCurve> ecParams) {
    return ecParams.entries
        .map(
          (entry) => _commands.setECKeyAttributes(entry.key, entry.value),
        )
        .toList();
  }

  List<List<int>> ecCurveParams(Iterable<ECCurve> ecCurves) {
    return ecCurves
        .map(
          (curve) => Uint8List.fromList(
              [curve.algorithm, curve.oid.length] + curve.oid),
        )
        .toList();
  }

  Future<Map<KeySlot, RSAKeyData>> generateRSAKey(
      Map<KeySlot, int> rsaParams) async {
    final generateResponses = await sendCommands(
        'generateRSAAsymmetricKey',
        [rsaKeyAttributes(rsaParams), generate(rsaParams.keys)],
        [
          rsaParams.keys.map((e) => e.fingerprint).toList(),
          rsaParams.keys.map((e) => e.genTime).toList(),
        ],
        verify: _commands.verifyAdminPin(_pinProvider.adminPin));
    return Map.fromEntries(generateResponses.mapIndexed((i, generateResponse) {
      if (generateResponse is SuccessfulResponse) {
        final keySlot = rsaParams.keys.elementAt(i);
        return MapEntry(
            keySlot, RSAKeyData.fromBytes(generateResponse.response, keySlot));
      } else if (generateResponse is ErrorResponse) {
        throw generateResponse.exception;
      }
      throw Exception('Invalid response type ${generateResponse.runtimeType}');
    }));
  }

  List<List<int>> rsaKeyAttributes(Map<KeySlot, int> rsaParams) {
    return rsaParams.entries
        .map(
          (entry) => _commands.setRsaKeyAttributes(entry.key, entry.value),
        )
        .toList();
  }

  List<List<int>> generate(Iterable<KeySlot> params) {
    return params
        .map(
          (keySlot) => _commands.generateAsymmetricKey(keySlot),
        )
        .toList();
  }

  Future<List<SmartCardResponse>> sendCommands(
      String method, List<List<List<int>>> input, List<List<int>> input2,
      {List<int>? verify}) async {
    try {
      List<Object?> result = await _channel.invokeMethod(method, [
        ...input
            .map((a) => a.map((e) => Uint8List.fromList(e)).toList())
            .toList(),
        ...input2,
        Uint8List.fromList(verify ?? [])
      ]);
      return result
          .whereType<Uint8List>()
          .map((e) => SmartCardResponse.fromBytes(e))
          .toList();
    } on PlatformException catch (e) {
      if (e.message == 'Tag was lost.' || e.message == 'Tag connection lost') {
        throw TagLostException();
      }
      if (e.message == 'Session invalidated by user' ||
          e.message == 'User canceled') {
        throw UserCanceledException();
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