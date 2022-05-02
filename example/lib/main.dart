import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:yubikit_flutter/piv/piv_key_algorithm.dart';
import 'package:yubikit_flutter/piv/piv_key_type.dart';
import 'package:yubikit_flutter/piv/piv_management_key_type.dart';
import 'package:yubikit_flutter/piv/piv_pin_policy.dart';
import 'package:yubikit_flutter/piv/piv_session.dart';

import 'package:yubikit_flutter/piv/piv_slot.dart';
import 'package:yubikit_flutter/piv/piv_touch_policy.dart';
import 'package:yubikit_flutter/yubikit_flutter.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Uint8List? signature;
  Uint8List? publicKey;
  late String data;

  @override
  void initState() {
    super.initState();
    data = "Hello World";
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
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Yubikit example app'),
        ),
        body: Center(
          child: Column(
            children: [
              ElevatedButton(
                  onPressed: () async => {
                        setSignature(await YubikitFlutter.pivSession()
                            .signWithKey(
                                YKFPIVSlot.signature,
                                YKFPIVKeyType.rsa2048,
                                YKFPIVKeyAlgorithm
                                    .rsaSignatureMessagePKCS1v15SHA512,
                                YubikitFlutterPivSession.defaultPin,
                                Uint8List.fromList(data.codeUnits)))
                      },
                  child: const Text("Sign")),
              ElevatedButton(
                  onPressed: () async => {
                        setPublicKey(await YubikitFlutter.pivSession()
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
                    Uint8List? publicKey = await YubikitFlutter.pivSession()
                        .decryptWithKey(
                            YKFPIVSlot.signature,
                            YKFPIVKeyAlgorithm.rsaEncryptionPKCS1,
                            YubikitFlutterPivSession.defaultPin,
                            Uint8List.fromList(data.codeUnits));
                    setState(() {
                      this.publicKey = publicKey;
                    });
                  },
                  child: const Text("Decrypt data")),
              ElevatedButton(
                  onPressed: () async {}, child: const Text("Encrypt data")),
              ElevatedButton(
                  onPressed: () async {
                    await YubikitFlutter.pivSession().reset();
                    setState(() {
                      publicKey = null;
                      signature = null;
                      data = "Hello World";
                    });
                  },
                  child: const Text("Reset")),
              Text("Signature: " + (base64.encode(signature ?? []))),
              Text("Public key: " + (base64.encode(publicKey ?? []))),
              Text("Data: " + data),
            ],
          ),
        ),
      ),
    );
  }
}
