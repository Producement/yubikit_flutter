import 'dart:async';
import 'dart:typed_data';

import 'package:yubikit_openpgp/smartcard/interface.dart';
import 'package:yubikit_openpgp/yubikit_openpgp.dart';

import 'piv/piv.dart';
import 'smartcard/smartcard.dart';

export 'package:yubikit_openpgp/yubikit_openpgp.dart';

export 'piv/key_algorithm.dart';
export 'piv/key_type.dart';
export 'piv/management_key_type.dart';
export 'piv/pin_policy.dart';
export 'piv/piv.dart';
export 'piv/slot.dart';
export 'piv/touch_policy.dart';
export 'smartcard/smartcard.dart';

class YubikitFlutter {
  const YubikitFlutter._internal();

  static YubikitFlutterPiv piv() {
    return const YubikitFlutterPiv();
  }

  static YubikitFlutterSmartCard smartCard() {
    return const YubikitFlutterSmartCard();
  }

  static YubikitOpenPGP openPGP() {
    return const YubikitOpenPGP(
        YubikitFlutterOpenPGPSmartCard(YubikitFlutterSmartCard()));
  }
}

class YubikitFlutterOpenPGPSmartCard extends SmartCardInterface {
  final YubikitFlutterSmartCard _smartCard;

  const YubikitFlutterOpenPGPSmartCard(this._smartCard);

  @override
  Future<Uint8List> sendCommand(List<int> input) async {
    return await _smartCard.sendCommand(Application.openpgp, input);
  }
}
