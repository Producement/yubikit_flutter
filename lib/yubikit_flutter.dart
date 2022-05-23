import 'dart:async';

import 'package:flutter/services.dart';
import 'package:yubikit_flutter/smartcard/session.dart';

import 'piv/session.dart';

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
      if (event == "deviceConnected") {
        yield YubikitEvent.deviceConnected;
      } else if (event == "deviceDisconnected") {
        yield YubikitEvent.deviceDisconnected;
      } else {
        yield YubikitEvent.unknown;
      }
    }
  }

  static YubikitFlutterPivSession pivSession() {
    return const YubikitFlutterPivSession();
  }

  static YubikitFlutterSmartCardSession smartCardSession() {
    return const YubikitFlutterSmartCardSession();
  }
}
