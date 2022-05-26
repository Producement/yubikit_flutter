import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:yubikit_flutter/yubikit_flutter.dart';

class PivPage extends StatefulWidget {
  const PivPage({Key? key}) : super(key: key);

  @override
  State<PivPage> createState() => _PivPageState();
}

class _PivPageState extends State<PivPage> {
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
              onPressed: () async => {
                    setSignature(await YubikitFlutter.piv().signWithKey(
                        YKFPIVSlot.signature,
                        YKFPIVKeyType.rsa2048,
                        YKFPIVKeyAlgorithm.rsaSignatureMessagePKCS1v15SHA512,
                        YubikitFlutterPiv.defaultPin,
                        data))
                  },
              child: const Text("Sign")),
          ElevatedButton(
              onPressed: () async => {
                    setPublicKey(await YubikitFlutter.piv().generateKey(
                        YKFPIVSlot.signature,
                        YKFPIVKeyType.rsa2048,
                        YKFPIVPinPolicy.def,
                        YKFPIVTouchPolicy.def,
                        YKFPIVManagementKeyType.tripleDES,
                        Uint8List.fromList(
                            YubikitFlutterPiv.defaultManagementKey),
                        YubikitFlutterPiv.defaultPin))
                  },
              child: const Text("Generate key")),
          ElevatedButton(
              onPressed: () async {
                Uint8List? decryptedData = await YubikitFlutter.piv()
                    .decryptWithKey(
                        YKFPIVSlot.signature,
                        YKFPIVKeyAlgorithm.rsaEncryptionPKCS1,
                        YubikitFlutterPiv.defaultPin,
                        data);
                setState(() {
                  data = decryptedData;
                });
              },
              child: const Text("Decrypt data")),
          ElevatedButton(
              onPressed: () async {
                Uint8List encryptedData = await YubikitFlutter.piv()
                    .encryptWithKey(YKFPIVKeyType.rsa2048, publicKey!, data);
                setState(() {
                  data = encryptedData;
                });
              },
              child: const Text("Encrypt data")),
          ElevatedButton(
              onPressed: () async {
                await YubikitFlutter.piv().reset();
                setState(() {
                  publicKey = null;
                  signature = null;
                  data = Uint8List.fromList("Hello World".codeUnits);
                });
              },
              child: const Text("Reset")),
          Text("Signature: ${base64.encode(signature ?? [])}"),
          Text("Public key: ${base64.encode(publicKey ?? [])}"),
          Text("Data: ${String.fromCharCodes(data)}"),
        ],
      ),
    );
  }
}
