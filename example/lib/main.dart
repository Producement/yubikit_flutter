import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:convert/convert.dart';
import 'package:yubikit_flutter/openpgp/info.dart';
import 'package:yubikit_flutter/openpgp/curve.dart';
import 'package:yubikit_flutter/openpgp/keyslot.dart';
import 'package:yubikit_flutter/openpgp/session.dart';
import 'package:yubikit_flutter/piv/piv_key_algorithm.dart';
import 'package:yubikit_flutter/piv/piv_key_type.dart';
import 'package:yubikit_flutter/piv/piv_management_key_type.dart';
import 'package:yubikit_flutter/piv/piv_pin_policy.dart';
import 'package:yubikit_flutter/piv/piv_session.dart';
import 'package:yubikit_flutter/piv/piv_slot.dart';
import 'package:yubikit_flutter/piv/piv_touch_policy.dart';
import 'package:yubikit_flutter/smartcard/application.dart';
import 'package:yubikit_flutter/smartcard/instruction.dart';
import 'package:yubikit_flutter/yubikit_flutter.dart';

void main() {
  runApp(const MaterialApp(home: MyApp()));
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Uint8List? signature;
  Uint8List? publicKey;
  late Uint8List data;
  late YubikitFlutter yubikitFlutter;

  @override
  void initState() {
    super.initState();
    data = Uint8List.fromList("Hello World".codeUnits);
    yubikitFlutter = YubikitFlutter.connect();
  }

  @override
  void dispose() {
    yubikitFlutter.stop();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yubikit example app'),
      ),
      body: Center(
        child: Column(
          children: [
            ElevatedButton(
                onPressed: () async => {
                      setSignature(await yubikitFlutter
                          .pivSession()
                          .signWithKey(
                              YKFPIVSlot.signature,
                              YKFPIVKeyType.rsa2048,
                              YKFPIVKeyAlgorithm
                                  .rsaSignatureMessagePKCS1v15SHA512,
                              YubikitFlutterPivSession.defaultPin,
                              data))
                    },
                child: const Text("Sign")),
            ElevatedButton(
                onPressed: () async => {
                      setPublicKey(await yubikitFlutter
                          .pivSession()
                          .generateKey(
                              YKFPIVSlot.signature,
                              YKFPIVKeyType.rsa2048,
                              YKFPIVPinPolicy.def,
                              YKFPIVTouchPolicy.def,
                              YKFPIVManagementKeyType.tripleDES,
                              Uint8List.fromList(YubikitFlutterPivSession
                                  .defaultManagementKey),
                              YubikitFlutterPivSession.defaultPin))
                    },
                child: const Text("Generate key")),
            ElevatedButton(
                onPressed: () async {
                  Uint8List? decryptedData = await yubikitFlutter
                      .pivSession()
                      .decryptWithKey(
                          YKFPIVSlot.signature,
                          YKFPIVKeyAlgorithm.rsaEncryptionPKCS1,
                          YubikitFlutterPivSession.defaultPin,
                          data);
                  setState(() {
                    data = decryptedData;
                  });
                },
                child: const Text("Decrypt data")),
            ElevatedButton(
                onPressed: () async {
                  Uint8List encryptedData = await yubikitFlutter
                      .pivSession()
                      .encryptWithKey(YKFPIVKeyType.rsa2048, publicKey!, data);
                  setState(() {
                    data = encryptedData;
                  });
                },
                child: const Text("Encrypt data")),
            ElevatedButton(
                onPressed: () async {
                  await yubikitFlutter.pivSession().reset();
                  setState(() {
                    publicKey = null;
                    signature = null;
                    data = Uint8List.fromList("Hello World".codeUnits);
                  });
                },
                child: const Text("Reset")),
            ElevatedButton(
                onPressed: () async {
                  await yubikitFlutter.start();
                  await yubikitFlutter
                      .smartCardSession()
                      .selectApplication(Application.openpgp);
                  Uint8List data = await yubikitFlutter
                      .smartCardSession()
                      .sendApdu(0x00, Instruction.getVersion, 0x00, 0x00,
                          Uint8List.fromList([]));
                  String version = data[0].toString() +
                      "." +
                      data[1].toString() +
                      "." +
                      data[2].toString();
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      content: Text("Application version: " + version),
                      actions: <Widget>[
                        ElevatedButton(
                          onPressed: () {
                            Navigator.of(ctx).pop();
                          },
                          child: const Text("Ok"),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text("Application version(APDU)")),
            ElevatedButton(
                onPressed: () async {
                  OpenPGPInfo.showOpenPGPInfo(
                      context, yubikitFlutter.openPGPSession());
                },
                child: const Text("OpenPGP info")),
            ElevatedButton(
                onPressed: () async {
                  var session = yubikitFlutter.openPGPSession();
                  await session.verifyAdmin(
                      YubikitFlutterOpenPGPSession.defaultAdminPin);
                  var pubKey = await session.generateECKey(
                      KeySlot.signature, ECCurve.ed25519);
                  debugPrint(pubKey);
                },
                child: const Text("OpenPGP generate")),
            ElevatedButton(
                onPressed: () async {
                  var session = yubikitFlutter.openPGPSession();
                  await session.verifyAdmin(
                      YubikitFlutterOpenPGPSession.defaultAdminPin);
                  var pubKey = await session.getECPublicKey(
                      KeySlot.signature, ECCurve.ed25519);
                  debugPrint(pubKey);
                },
                child: const Text("OpenPGP pubKey")),
            ElevatedButton(
                onPressed: () async {
                  var session = yubikitFlutter.openPGPSession();
                  await session
                      .verifyPin(YubikitFlutterOpenPGPSession.defaultPin);
                  var signature = await session.sign(Uint8List.fromList(
                      "eyJhbGciOiJFZERTQSJ9.eyJleHAiOjE2NTE4MzE0NjksImlhdCI6MTY1MTgyOTY2OSwiYXV0aG9yaXRpZXMiOlsiUk9MRV9VU0VSIl19"
                          .codeUnits));
                  debugPrint(base64.encode(signature));
                },
                child: const Text("OpenPGP sign")),
            Text("Signature: " + (base64.encode(signature ?? []))),
            Text("Public key: " + (base64.encode(publicKey ?? []))),
            Text("Data: " + String.fromCharCodes(data)),
          ],
        ),
      ),
    );
  }
}
