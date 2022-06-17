import 'package:flutter/material.dart';
import 'package:yubikit_flutter/yubikit_flutter.dart';
import 'package:yubikit_flutter_example/batch_service.dart';

class OpenPGPInfoWidget extends StatelessWidget {
  final OpenPGPInfo openPGPInfo;

  const OpenPGPInfoWidget(this.openPGPInfo, {Key? key}) : super(key: key);

  static Future<void> showOpenPGPInfo(
      BuildContext context, SmartCardInterface interface) async {
    final batchService =
        BatchOpenPGPService(interface, const YubikitOpenPGPCommands());
    final info = await batchService.getInfo();
    await showDialog(
        context: context, builder: (ctx) => OpenPGPInfoWidget(info));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
              "OpenPGP version: ${openPGPInfo.openPGPVersion.major}.${openPGPInfo.openPGPVersion.minor}"),
          const Text(""),
          Text("PIN tries remaining: ${openPGPInfo.retries.pin}"),
          Text("Reset code tries remaining: ${openPGPInfo.retries.reset}"),
          Text("Admin PIN tries remaining: ${openPGPInfo.retries.admin}"),
          const Text(""),
          const Text("Touch policies"),
          Text("Signature key ${openPGPInfo.signatureTouch.name}"),
          Text("Encryption key ${openPGPInfo.encryptionTouch.name}"),
          Text("Authentication key ${openPGPInfo.authenticationTouch.name}"),
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
