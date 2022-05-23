import 'dart:typed_data';

import 'package:yubikit_flutter/smartcard/session.dart';
import 'package:yubikit_openpgp/smartcard/interface.dart';

class YubikeySmartCardInterface extends SmartCardInterface {
  final YubikitFlutterSmartCardSession _smartCardSession;

  const YubikeySmartCardInterface(this._smartCardSession);

  @override
  Future<Uint8List> sendCommand(List<int> input) {
    return _smartCardSession.sendCommand(Uint8List.fromList(input));
  }
}