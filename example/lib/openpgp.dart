import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:yubikit_flutter/smartcard/session.dart';
import 'package:yubikit_flutter/yubikit_flutter.dart';
import 'package:yubikit_flutter_example/nfc_dialog.dart';
import 'package:yubikit_openpgp/curve.dart';
import 'package:yubikit_openpgp/interface.dart';
import 'package:yubikit_openpgp/keyslot.dart';
import 'package:yubikit_openpgp/smartcard/application.dart';

import 'interface.dart';
import 'openpgp_info.dart';

class OpenPGPPage extends StatefulWidget {
  const OpenPGPPage({Key? key}) : super(key: key);

  @override
  State<OpenPGPPage> createState() => _OpenPGPPageState();
}

class _OpenPGPPageState extends State<OpenPGPPage> {
  late YubikitFlutterSmartCardSession session;
  late OpenPGPInterface interface;
  Uint8List? signature;
  Uint8List? publicKey;
  String? encryptedData;

  @override
  void initState() {
    session = YubikitFlutterSmartCardSession();
    interface = OpenPGPInterface(YubikeySmartCardInterface(session));
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
                await session.doWithApplication(Application.openpgp, () async {
                  await OpenPGPInfo.showOpenPGPInfo(context, interface);
                });
              },
              child: const Text("Info")),
          ElevatedButton(
              onPressed: () async {
                await session.doWithApplication(Application.openpgp, () async {
                  await interface.verifyAdmin(OpenPGPInterface.defaultAdminPin);
                  await interface.generateECKey(
                      KeySlot.encryption, ECCurve.x25519);
                  if (!mounted) return;
                  await NFCDialog.showNfcDialog(context);
                });
              },
              child: const Text("Generate")),
          ElevatedButton(
              onPressed: () async {
                await session.doWithApplication(Application.openpgp, () async {
                  await interface.reset();
                });
              },
              child: const Text("Reset")),
          StreamBuilder<YubikitEvent>(
              stream: YubikitFlutter.eventStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text(snapshot.error.toString());
                } else {
                  switch (snapshot.connectionState) {
                    case ConnectionState.none:
                      return const CircularProgressIndicator();
                    case ConnectionState.waiting:
                      return const CircularProgressIndicator();
                    case ConnectionState.active:
                      return Text("Device state: ${snapshot.data?.name}",
                          key: Key(snapshot.data?.name ?? 'N/A'));
                    case ConnectionState.done:
                      return Column();
                  }
                }
              }),
        ],
      ),
    );
  }
}