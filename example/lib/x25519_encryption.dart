import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

class EncryptedData {
  final SimplePublicKey _cipherTextPublicKey;
  final SecretBox _secretBox;

  EncryptedData(this._cipherTextPublicKey, this._secretBox);

  Map<String, dynamic> toJson() => {
        'ciphertext': base64Encode(_secretBox.cipherText),
        'nonce': base64Encode(_secretBox.nonce),
        'authTag': base64Encode(_secretBox.mac.bytes),
        'ciphertextPubKey': base64Encode(_cipherTextPublicKey.bytes),
      };

  EncryptedData.fromJson(Map<String, dynamic> json)
      : _cipherTextPublicKey = SimplePublicKey(
            base64Decode(json['ciphertextPubKey']),
            type: KeyPairType.x25519),
        _secretBox = SecretBox(base64Decode(json['ciphertext']),
            nonce: base64Decode(json['nonce']),
            mac: Mac(base64Decode(json['authTag'])));

  SimplePublicKey getCipherTextPublicKey() => _cipherTextPublicKey;
}

class X25519Encryption {
  final _symmetricAlgorithm = AesCbc.with256bits(
    macAlgorithm: Hmac.sha512(),
  );

  Future<EncryptedData> encrypt(
      List<int> message, List<int> publicKeyBytes) async {
    final algorithm = X25519();
    final keyPair = await algorithm.newKeyPair();
    final publicKey = SimplePublicKey(publicKeyBytes, type: KeyPairType.x25519);
    var sharedSecret = await algorithm.sharedSecretKey(
        keyPair: keyPair, remotePublicKey: publicKey);
    var encryptedData = await _aesEncrypt(message, sharedSecret);
    var cipherTextPublicKey = await keyPair.extractPublicKey();
    return EncryptedData(cipherTextPublicKey, encryptedData);
  }

  Future<SecretBox> _aesEncrypt(List<int> message, SecretKey secretKey) async {
    final secretBox = await _symmetricAlgorithm.encrypt(
      message,
      secretKey: secretKey,
    );
    return secretBox;
  }

  Future<Uint8List> decrypt(
      EncryptedData encryptedData, List<int> secretKeyBytes) async {
    final secretKey = SecretKey(secretKeyBytes);
    List<int> decrypted =
        await _aesDecrypt(encryptedData._secretBox, secretKey);
    return Uint8List.fromList(decrypted);
  }

  Future<List<int>> _aesDecrypt(
      SecretBox secretBox, SecretKey secretKey) async {
    final message = await _symmetricAlgorithm.decrypt(
      secretBox,
      secretKey: secretKey,
    );
    return message;
  }
}
