import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yubikit_flutter_example/x25519_encryption.dart';

void main() {
  final algorithm = X25519();
  final x25519Encryption = X25519Encryption();
  test("encrypts and decrypts", () async {
    const message = "Hello World!";
    final keyPair = await algorithm.newKeyPair();
    final publicKeyBytes = await keyPair.extractPublicKey();
    final encryptedData =
        await x25519Encryption.encrypt(message.codeUnits, publicKeyBytes.bytes);
    final secretKey = await algorithm.sharedSecretKey(
        keyPair: keyPair,
        remotePublicKey: encryptedData.getCipherTextPublicKey());
    final secretKeyBytes = await secretKey.extractBytes();
    final decryptedData =
        await x25519Encryption.decrypt(encryptedData, secretKeyBytes);
    expect(String.fromCharCodes(decryptedData), equals(message));
  });
}
