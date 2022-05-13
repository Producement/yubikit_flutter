import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:convert/convert.dart';
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
  String? encryptedData;

  @override
  void initState() {
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
                    KeySlot.encryption, ECCurve.x25519);
                setPublicKey(pubKey);
                session.stop();
              },
              child: const Text("Generate encryption key")),
          ElevatedButton(
              onPressed: () async {
                var session = YubikitFlutter.openPGPSession();
                await session
                    .verifyAdmin(YubikitFlutterOpenPGPSession.defaultAdminPin);
                var pubKey = await session.getECPublicKey(KeySlot.encryption);
                setPublicKey(pubKey);
                session.stop();
              },
              child: const Text("Get encryption key")),
          ElevatedButton(
              onPressed: () async {
                var session = YubikitFlutter.openPGPSession();
                await session
                    .verifyPin(YubikitFlutterOpenPGPSession.defaultPin);
                var signature = await session
                    .sign(Uint8List.fromList("Hello World".codeUnits));
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
          ElevatedButton(
              onPressed: () async {
                var session = YubikitFlutter.openPGPSession();
                debugPrint("VERIFY PIN");
                await session
                    .verifyPin(YubikitFlutterOpenPGPSession.defaultPin);
                debugPrint("PIN VERIFIED");
                final pubKey = BigInt.parse("7480317426394696936448527343812174929534157707887635210617056164323067967739714");
                final puKeyAsBytes = _bigIntToUint8List(pubKey).sublist(1);
                final secret = await session.ecSharedSecret(puKeyAsBytes);
                debugPrint("SUCCESS");
                debugPrint(hex.encode(secret));
                session.stop();
              },
              child: const Text("Shared secret")),
          Text("Signature: " + (base64.encode(signature ?? []))),
          Text("Public key: " + (base64.encode(publicKey ?? []))),
          Text("Encrypted data: " + (encryptedData ?? "")),
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
                      return Text("Device state: ${snapshot.data?.name}");
                    case ConnectionState.done:
                      return Column();
                  }
                }
              }),
        ],
      ),
    );
  }

  String armor(List<int> packet) {
    var content = base64Encode(packet);
    return '''-----BEGIN PGP PUBLIC KEY BLOCK-----

$content

-----END PGP PUBLIC KEY BLOCK-----
''';
  }
}

BigInt decodeBigInt(List<int> bytes) {
  BigInt result = new BigInt.from(0);
  for (int i = 0; i < bytes.length; i++) {
    result += new BigInt.from(bytes[bytes.length - i - 1]) << (8 * i);
  }
  return result;
}

Uint8List _bigIntToUint8List(BigInt bigInt) =>
    _bigIntToByteData(bigInt).buffer.asUint8List();

ByteData _bigIntToByteData(BigInt bigInt) {
  final data = ByteData((bigInt.bitLength / 8).ceil());
  var _bigInt = bigInt;

  for (var i = 1; i <= data.lengthInBytes; i++) {
    data.setUint8(data.lengthInBytes - i, _bigInt.toUnsigned(8).toInt());
    _bigInt = _bigInt >> 8;
  }

  return data;
}
