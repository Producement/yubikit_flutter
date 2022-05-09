import 'dart:typed_data';

import 'package:crypto/crypto.dart';

enum KdfAlgorithm {
  none,
  kdfItersaltedS2k,
}

extension KdfAlgorithmValue on KdfAlgorithm {
  int get value {
    switch (this) {
      case KdfAlgorithm.none:
        return 0x00;
      case KdfAlgorithm.kdfItersaltedS2k:
        return 0x03;
    }
  }
}

const int pw1 = 0x81;
const int pw3 = 0x83;

enum HashAlgorithm {
  sha256,
  sha512,
}

extension HashAlgorithmValue on HashAlgorithm {
  int get value {
    switch (this) {
      case HashAlgorithm.sha256:
        return 0x08;
      case HashAlgorithm.sha512:
        return 0x0A;
    }
  }

  Hash get digest {
    switch (this) {
      case HashAlgorithm.sha256:
        return sha256;
      case HashAlgorithm.sha512:
        return sha512;
    }
  }
}

class KdfData {
  KdfAlgorithm algorithm;
  HashAlgorithm hashAlgorithm;
  int iterationCount;
  Iterable<int>? pw1SaltBytes;
  Iterable<int> pw3SaltBytes;

  KdfData(this.algorithm, this.hashAlgorithm, this.iterationCount,
      this.pw1SaltBytes, this.pw3SaltBytes);

  factory KdfData.parse(Uint8List data) {
    if (data[0] == 0x81 && data[1] == 0x01 && data[2] == 0x00) {
      return KdfData(KdfAlgorithm.none, HashAlgorithm.sha256, 0, null,
          Uint8List.fromList([]));
    }
    //TODO: support other KDF algorithms
    throw Exception("KDF is not implemented properly yet.");
  }

  Iterable<int> process(int pw, Iterable<int> pin) {
    if (algorithm == KdfAlgorithm.none) {
      return pin;
    } else if (algorithm == KdfAlgorithm.kdfItersaltedS2k) {
      late Iterable<int> salt;
      if (pw == pw1) {
        salt = pw1SaltBytes!;
      } else if (pw == pw3) {
        salt = pw1SaltBytes ?? pw3SaltBytes;
      }
      return kdfItersaltedS2k(pin, salt);
    }
    throw Exception("Algorithm not supported!");
  }

  Iterable<int> kdfItersaltedS2k(Iterable<int> pin, Iterable<int> salt) {
    Iterable<int> data = salt.followedBy(pin);
    Hash digest = hashAlgorithm.digest;
    List<int> input = List.empty();
    int trailingBytes = iterationCount % data.length;
    int dataCount = ((iterationCount - trailingBytes) / data.length) as int;
    Iterable<int> trailing = data.skip(trailingBytes);
    for (int i = 0; i < dataCount; i++) {
      input.addAll(data);
    }
    input.addAll(trailing);
    return Uint8List.fromList(digest.convert(input).bytes);
  }
}
