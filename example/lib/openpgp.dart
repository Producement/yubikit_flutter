import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:flutter/material.dart';
import 'package:yubikit_flutter/yubikit_flutter.dart';
import 'package:yubikit_openpgp/key_data.dart';

import 'openpgp_info.dart';
import 'text_dialog.dart';

class OpenPGPPage extends StatefulWidget {
  const OpenPGPPage({Key? key}) : super(key: key);

  @override
  State<OpenPGPPage> createState() => _OpenPGPPageState();
}

class _OpenPGPPageState extends State<OpenPGPPage> {
  late YubikitOpenPGP interface;
  Uint8List? signature;
  Uint8List? publicKey;
  String? encryptedData;

  @override
  void initState() {
    interface = YubikitFlutter.openPGP();
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void setSignature(Uint8List? newSignature) {
    setState(() {
      signature = newSignature;
    });
  }

  void setPublicKey(Uint8List? newPublicKey) {
    setState(() {
      publicKey = newPublicKey;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        children: [
          ElevatedButton(
              onPressed: () async {
                await OpenPGPInfo.showOpenPGPInfo(context, interface);
              },
              child: const Text("Info")),
          ElevatedButton(
              onPressed: () async {
                final key = await interface.getPublicKey(KeySlot.encryption);
                if (!mounted) return;
                if (key is RSAKeyData) {
                  await TextDialog.showTextDialog(context,
                      'RSA key: ${hex.encode(key.modulus)} ${hex.encode(key.exponent)}');
                } else if (key is ECKeyData) {
                  await TextDialog.showTextDialog(
                      context, 'EC Key: ${hex.encode(key.publicKey)}');
                }
              },
              child: const Text("Get encryption EC pubkey")),
          ElevatedButton(
              onPressed: () async {
                final key = await interface.generateECKey(
                    KeySlot.encryption, ECCurve.x25519);
                if (!mounted) return;
                await TextDialog.showTextDialog(context, 'Public key: $key');
              },
              child: const Text("Generate encryption EC key")),
          ElevatedButton(
              onPressed: () async {
                await interface.reset();
              },
              child: const Text("Reset")),
        ],
      ),
    );
  }
}
