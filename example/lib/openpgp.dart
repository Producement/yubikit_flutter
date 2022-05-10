import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:yubikit_flutter/openpgp/curve.dart';
import 'package:yubikit_flutter/openpgp/info.dart';
import 'package:yubikit_flutter/openpgp/keyslot.dart';
import 'package:yubikit_flutter/openpgp/session.dart';
import 'package:yubikit_flutter/yubikit_flutter.dart';

class OpenPGPPage extends StatefulWidget {
  const OpenPGPPage({Key? key}) : super(key: key);

  @override
  State<OpenPGPPage> createState() => _OpenPGPPageState();
}

class _OpenPGPPageState extends State<OpenPGPPage> {
  Uint8List? signature;
  Uint8List? publicKey;
  late Uint8List data;

  @override
  void initState() {
    super.initState();
    data = Uint8List.fromList("Hello World".codeUnits);
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
                var session = YubikitFlutter.openPGPSession();
                await OpenPGPInfo.showOpenPGPInfo(context, session);
                session.stop();
              },
              child: const Text("Info")),
          ElevatedButton(
              onPressed: () async {
                var session = YubikitFlutter.openPGPSession();
                await session
                    .verifyAdmin(YubikitFlutterOpenPGPSession.defaultAdminPin);
                var pubKey = await session.generateECKey(
                    KeySlot.signature, ECCurve.ed25519);
                setPublicKey(pubKey);
                session.stop();
              },
              child: const Text("Generate signature key")),
          ElevatedButton(
              onPressed: () async {
                var session = YubikitFlutter.openPGPSession();
                await session
                    .verifyAdmin(YubikitFlutterOpenPGPSession.defaultAdminPin);
                var pubKey = await session.getECPublicKey(
                    KeySlot.signature, ECCurve.ed25519);
                setPublicKey(pubKey);
                session.stop();
              },
              child: const Text("Get signature key")),
          ElevatedButton(
              onPressed: () async {
                var session = YubikitFlutter.openPGPSession();
                await session
                    .verifyPin(YubikitFlutterOpenPGPSession.defaultPin);
                var signature = await session.sign(data);
                setSignature(signature);
                session.stop();
              },
              child: const Text("Sign")),
          ElevatedButton(
              onPressed: () async {
                var session = YubikitFlutter.openPGPSession();
                await session.reset();
                session.stop();
              },
              child: const Text("Reset")),
          Text("Signature: " + (base64.encode(signature ?? []))),
          Text("Public key: " + (base64.encode(publicKey ?? []))),
          Text("Data: " + String.fromCharCodes(data)),
          StreamBuilder(
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
                      return Text("Device state: ${snapshot.data}");
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
