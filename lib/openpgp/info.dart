import 'package:flutter/material.dart';
import 'package:tuple/tuple.dart';
import 'package:yubikit_flutter/openpgp/session.dart';

import 'keyslot.dart';
import 'touch_mode.dart';

class OpenPGPInfo extends StatelessWidget {
  final Tuple2 openPGPVersion;
  final Tuple3 applicationVersion;
  final PinRetries retries;
  final TouchMode signatureTouch;
  final TouchMode encryptionTouch;
  final TouchMode authenticationTouch;

  const OpenPGPInfo(this.openPGPVersion, this.applicationVersion, this.retries,
      this.signatureTouch, this.encryptionTouch, this.authenticationTouch,
      {Key? key})
      : super(key: key);

  static Future<void> showOpenPGPInfo(
      BuildContext context, YubikitFlutterOpenPGPSession openPGPSession) async {
    Tuple2 openPGPVersion = await openPGPSession.getOpenPGPVersion();
    Tuple3 applicationVersion = await openPGPSession.getApplicationVersion();
    PinRetries retries = await openPGPSession.getRemainingPinTries();
    TouchMode signatureTouch = await openPGPSession.getTouch(KeySlot.signature);
    TouchMode encryptionTouch =
        await openPGPSession.getTouch(KeySlot.encryption);
    TouchMode authenticationTouch =
        await openPGPSession.getTouch(KeySlot.authentication);
    showDialog(
        context: context,
        builder: (ctx) => OpenPGPInfo(openPGPVersion, applicationVersion,
            retries, signatureTouch, encryptionTouch, authenticationTouch));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text("OpenPGP version: $openPGPVersion"),
          Text("Application version: $applicationVersion"),
          const Text(""),
          Text("PIN tries remaining: ${retries.pin}"),
          Text("Reset code tries remaining: ${retries.reset}"),
          Text("Admin PIN tries remaining: ${retries.admin}"),
          const Text(""),
          const Text("Touch policies"),
          Text("Signature key ${signatureTouch.name}"),
          Text("Encryption key ${encryptionTouch.name}"),
          Text("Authentication key ${authenticationTouch.name}"),
        ],
      ),
      actions: <Widget>[
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text("Ok"),
        ),
      ],
    );
  }
}