import 'dart:async';

import 'package:flutter/services.dart';
import 'package:yubikit_openpgp/yubikit_openpgp.dart';
import 'smartcard/smartcard.dart';
import 'piv/piv.dart';

export 'smartcard/smartcard.dart';
export 'piv/piv.dart';
export 'piv/key_algorithm.dart';
export 'piv/key_type.dart';
export 'piv/management_key_type.dart';
export 'piv/pin_policy.dart';
export 'piv/slot.dart';
export 'piv/touch_policy.dart';
export 'package:yubikit_openpgp/yubikit_openpgp.dart';

enum YubikitEvent {
  deviceConnected,
  deviceDisconnected,
  unknown,
}

class YubikitFlutter {
  static const EventChannel _eventChannel =
      EventChannel('yubikit_flutter_status');

  const YubikitFlutter._internal();

  static Stream<YubikitEvent> eventStream() async* {
    final events = _eventChannel.receiveBroadcastStream();
    await for (final event in events) {
      if (event == 'deviceConnected') {
        yield YubikitEvent.deviceConnected;
      } else if (event == 'deviceDisconnected') {
        yield YubikitEvent.deviceDisconnected;
      } else {
        yield YubikitEvent.unknown;
      }
    }
  }

  static YubikitFlutterPiv piv() {
    return const YubikitFlutterPiv();
  }

  static YubikitFlutterSmartCard smartCard() {
    return const YubikitFlutterSmartCard();
  }

  static YubikitOpenPGP openPGP() {
    return const YubikitOpenPGP(YubikitFlutterSmartCard());
  }
}
