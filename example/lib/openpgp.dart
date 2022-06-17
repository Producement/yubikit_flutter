import 'package:convert/convert.dart';
import 'package:flutter/material.dart';
import 'package:yubikit_flutter/yubikit_flutter.dart';
import 'package:yubikit_flutter_example/batch_service.dart';

import 'openpgp_info.dart';
import 'text_dialog.dart';

class OpenPGPPage extends StatelessWidget {
  const OpenPGPPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          ElevatedButton(
              onPressed: () async {
                await OpenPGPInfoWidget.showOpenPGPInfo(
                    context, YubikitFlutter.smartCard());
              },
              child: const Text("Info")),
          ElevatedButton(
              onPressed: () async {
                final batchService = BatchOpenPGPService(
                    YubikitFlutter.smartCard(), const YubikitOpenPGPCommands());
                await batchService.getAllKeys().then((keyMap) async {
                  for (var key in keyMap.values) {
                    if (key is RSAKeyData) {
                      await TextDialog.showTextDialog(context,
                          'RSA key: ${hex.encode(key.modulus)} ${hex.encode(key.exponent)}');
                    } else if (key is ECKeyData) {
                      await TextDialog.showTextDialog(
                          context, 'EC Key: ${hex.encode(key.publicKey)}');
                    }
                  }
                });
              },
              child: const Text("Get keys")),
          ElevatedButton(
              onPressed: () async {
                await YubikitFlutter.openPGP()
                    .rsaSign([0x00, 0x01, 0x02]).then((key) async {
                  await TextDialog.showTextDialog(
                      context, 'RSA signature: ${hex.encode(key)}');
                });
              },
              child: const Text("RSA sign")),
          ElevatedButton(
              onPressed: () async {
                await YubikitFlutter.openPGP()
                    .ecSign([0x00, 0x01, 0x02]).then((key) async {
                  await TextDialog.showTextDialog(
                      context, 'EC signature: ${hex.encode(key)}');
                });
              },
              child: const Text("EC sign")),
          ElevatedButton(
              onPressed: () async {
                await YubikitFlutter.openPGP()
                    .generateECKey(KeySlot.encryption, ECCurve.x25519)
                    .then((key) async {
                  await TextDialog.showTextDialog(context, 'Public key: $key');
                });
              },
              child: const Text("Generate encryption EC key")),
          ElevatedButton(
              onPressed: () async {
                await YubikitFlutter.openPGP().reset();
              },
              child: const Text("Reset")),
        ],
      ),
    );
  }
}
