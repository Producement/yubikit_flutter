import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:yubikit_flutter/piv/piv_key_algorithm.dart';
import 'package:yubikit_flutter/piv/piv_key_type.dart';

import 'package:yubikit_flutter/piv/piv_slot.dart';
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
  YubikitFlutter? _yubikitFlutter;
  Uint8List? signature;
  Uint8List? publicKey;

  @override
  void initState() {
    super.initState();
    YubikitFlutter.connect().then((value) => _yubikitFlutter = value);
  }

  @override
  void dispose() {
    _yubikitFlutter?.disconnect();
    _yubikitFlutter = null;
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
                        setSignature(await _yubikitFlutter
                            ?.pivSession()
                            .signWithKey(
                                YKFPIVSlot.signature,
                                YKFPIVKeyType.rsa2048,
                                YKFPIVKeyAlgorithm
                                    .rsaSignatureMessagePKCS1v15SHA512,
                                "122087",
                                Uint8List.fromList("Hello World".codeUnits)))
                      },
                  child: const Text("Sign")),
              ElevatedButton(
                  onPressed: () async => {
                        setPublicKey(await _yubikitFlutter
                            ?.pivSession()
                            .getPublicKey(YKFPIVSlot.signature))
                      },
                  child: const Text("Get PK")),
              Text("Signature: " + (base64.encode(signature ?? []))),
              Text("Public key: " + (base64.encode(publicKey ?? []))),
            ],
          ),
        ),
      ),
    );
  }
}
