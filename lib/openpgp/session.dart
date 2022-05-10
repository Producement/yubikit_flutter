import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:tuple/tuple.dart';
import 'package:yubikit_flutter/openpgp/fingerprint.dart';
import 'package:yubikit_flutter/openpgp/tlv.dart';
import 'package:yubikit_flutter/smartcard/session.dart';

import '../smartcard/application.dart';
import '../smartcard/instruction.dart';
import 'curve.dart';
import 'data_object.dart';
import 'kdf.dart';
import 'keyslot.dart';
import 'touch_mode.dart';

class YubikitFlutterOpenPGPSession {
  static const String defaultPin = "123456";
  static const String defaultAdminPin = "12345678";
  final YubikitFlutterSmartCardSession _smartCardSession;
  Application application = Application.openpgp;
  Tuple3? _appVersion;

  Future<Tuple3> get applicationVersion async {
    return _appVersion ??= await getApplicationVersion();
  }

  YubikitFlutterOpenPGPSession(this._smartCardSession) {
    _smartCardSession.start();
    _smartCardSession.selectApplication(Application.openpgp);
  }

  void stop() async {
    await _smartCardSession.stop();
  }

  Uint8List _formatECAttributes(KeySlot keySlot, ECCurve curve) {
    late int algorithm;
    if ([ECCurve.ed25519, ECCurve.x25519].contains(curve)) {
      algorithm = 0x16;
    } else if (keySlot == KeySlot.encryption) {
      algorithm = 0x12;
    } else {
      algorithm = 0x13;
    }
    return Uint8List.fromList([algorithm].followedBy(curve.oid).toList());
  }

  Future<Uint8List> generateECKey(KeySlot keySlot, ECCurve curve) async {
    requireVersion(5, 2, 0);
    Uint8List attributes = _formatECAttributes(keySlot, curve);
    _setData(keySlot.keyId, attributes);
    Uint8List response = await _smartCardSession.sendApdu(
        0x00, Instruction.generateAsym, 0x80, 0x00, keySlot.crt);
    TlvData data = TlvData.parse(response).get(0x7F49);
    Uint8List publicKey = data.getValue(0x86);
    await _setData(
        keySlot.fingerprint,
        Uint8List.fromList(FingerprintCalculator.calculateFingerprint(
            BigInt.parse(hex.encode(publicKey), radix: 16), curve)));
    return publicKey;
  }

  Future<Uint8List> getECPublicKey(KeySlot keySlot, ECCurve curveName) async {
    Uint8List response = await _smartCardSession.sendApdu(
        0x00, Instruction.generateAsym, 0x81, 0x00, keySlot.crt);
    TlvData data = TlvData.parse(response).get(0x7F49);
    return data.getValue(0x86);
  }

  Future<Uint8List> sign(Uint8List data) async {
    var digest = sha512.convert(data);
    Uint8List response = await _smartCardSession.sendApdu(
        0x00,
        Instruction.performSecurityOperation,
        0x9E,
        0x9A,
        Uint8List.fromList(digest.bytes));
    return response;
  }

  Future<TouchMode> getTouch(KeySlot keySlot) async {
    List<TouchMode> supported = await getSupportedTouchModes();
    if (supported.isEmpty) {
      throw Exception("Touch policy is available on YubiKey 4 or later.");
    }
    Uint8List data = await _getData(keySlot.uif);
    return TouchModeValues.parse(data);
  }

  static const int _touchMethodButton = 0x20;

  Future<void> setTouch(KeySlot keySlot, TouchMode mode) async {
    List<TouchMode> supported = await getSupportedTouchModes();
    if (supported.isEmpty) {
      throw Exception("Touch policy is available on YubiKey 4 or later.");
    }
    if (!supported.contains(mode)) {
      throw Exception("Touch policy not available on this device.");
    }
    await _setData(
        keySlot.uif, Uint8List.fromList([mode.value, _touchMethodButton]));
  }

  Future<Tuple2<int, int>> getOpenPGPVersion() async {
    Uint8List data = await _getData(DataObject.aid.value);
    return Tuple2(data[6], data[7]);
  }

  Future<Tuple3<int, int, int>> getApplicationVersion() async {
    Uint8List data = await _smartCardSession.sendApdu(
        0x00, Instruction.getVersion, 0x00, 0x00, Uint8List.fromList([]));
    var hexData = hex.encode(data);
    return Tuple3(int.parse(hexData.substring(0, 2)),
        int.parse(hexData.substring(2, 4)), int.parse(hexData.substring(4, 6)));
  }

  Future<PinRetries> getRemainingPinTries() async {
    Uint8List data = await _getData(DataObject.pwStatus.value);
    return PinRetries(data[4], data[5], data[6]);
  }

  Future<void> setPinRetries(int pw1Tries, int pw2Tries, int pw3Tries) async {
    if (await applicationVersion > const Tuple3(1, 0, 0) &&
        await applicationVersion < const Tuple3(1, 0, 7)) {
      throw Exception(
          "Setting PIN retry counters requires version 1.0.7 or later.");
    }
    if (await applicationVersion > const Tuple3(4, 0, 0) &&
        await applicationVersion < const Tuple3(4, 3, 1)) {
      throw Exception(
          "Setting PIN retry counters requires version 4.3.1 or later.");
    }
    await _smartCardSession.sendApdu(0x00, Instruction.setPinRetries, 0x00,
        0x00, Uint8List.fromList([pw1Tries, pw2Tries, pw3Tries]));
  }

  Future<KdfData> _getKdf() async {
    Uint8List data = await _getData(DataObject.kdf.value);
    return KdfData.parse(data);
  }

  Future<void> _verify(int pw, String pin) async {
    Iterable<int> actualPin = (await _getKdf()).process(pw, pin.codeUnits);
    Uint8List response = await _smartCardSession.sendApdu(0x00,
        Instruction.verify, 0, pw, Uint8List.fromList(actualPin.toList()));
    handleErrors(response);
  }

  Future<void> verifyPin(String pin) async {
    await _verify(pw1, pin);
  }

  Future<void> verifyAdmin(String pin) async {
    await _verify(pw3, pin);
  }

  Future<void> reset() async {
    if (await applicationVersion < const Tuple3(1, 0, 6)) {
      throw Exception(
          "Resetting OpenPGP data requires version 1.0.6 or later.");
    }
    await _blockPins();
    await _smartCardSession.sendApdu(
        0x00, Instruction.terminate, 0, 0, Uint8List.fromList([]));
    await _smartCardSession.sendApdu(
        0x00, Instruction.activate, 0, 0, Uint8List.fromList([]));
  }

  Future<void> _blockPins() async {
    var invalidPin = Uint8List.fromList([0, 0, 0, 0, 0, 0, 0, 0]);
    PinRetries retries = await getRemainingPinTries();
    for (var _ in Iterable.generate(retries.pin)) {
      try {
        await _smartCardSession.sendApdu(
            0x00, Instruction.verify, 0x00, pw1, invalidPin);
      } catch (e) {
        //Ignore
      }
    }
    for (var _ in Iterable.generate(retries.admin)) {
      try {
        await _smartCardSession.sendApdu(
            0x00, Instruction.verify, 0x00, pw3, invalidPin);
      } catch (e) {
        //Ignore
      }
    }
  }

  void requireVersion(int first, int second, int third) async {
    if (await applicationVersion < Tuple3(first, second, third)) {
      throw Exception("Application version $applicationVersion not supported!");
    }
  }

  Future<List<TouchMode>> getSupportedTouchModes() async {
    if (await applicationVersion < const Tuple3(4, 2, 0)) {
      return [];
    }
    if (await applicationVersion < const Tuple3(5, 2, 1)) {
      return [TouchMode.on, TouchMode.off, TouchMode.fixed];
    }
    return TouchMode.values;
  }

  Future<bool> supportsAttestation() async {
    return !(await applicationVersion < const Tuple3(5, 2, 1));
  }

  Future<Uint8List> _getData(int cmd) async {
    Uint8List response = await _smartCardSession.sendApdu(0x00,
        Instruction.getData, cmd >> 8, cmd & 0xFF, Uint8List.fromList([]));
    return response;
  }

  Future<Uint8List> _setData(int cmd, Uint8List data) async {
    Uint8List response = await _smartCardSession.sendApdu(
        0x00, Instruction.putData, cmd >> 8, cmd & 0xFF, data);
    return response;
  }

  void handleErrors(Uint8List response) {
    //TODO: improve error handling
    if (response.isNotEmpty && response[0] != 0x90) {
      throw Exception("Error: ${hex.encode(response)}");
    }
  }
}

class PinRetries {
  int pin, reset, admin;

  PinRetries(this.pin, this.reset, this.admin);
}

extension Tuple3Compare on Tuple3 {
  bool operator <(Tuple3 other) {
    if (item1 < other.item1) {
      return true;
    } else if (item1 == other.item1) {
      if (item2 < other.item2) {
        return true;
      } else if (item2 == other.item2) {
        return item3 < other.item3;
      }
    }
    return false;
  }

  bool operator >(Tuple3 other) {
    if (item1 > other.item1) {
      return true;
    } else if (item1 == other.item1) {
      if (item2 > other.item2) {
        return true;
      } else if (item2 == other.item2) {
        return item3 > other.item3;
      }
    }
    return false;
  }
}
