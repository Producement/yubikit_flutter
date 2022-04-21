enum YKFPIVKeyAlgorithm {
  ecdsaSignatureMessageX962SHA256,
  rsaSignatureMessagePKCS1v15SHA512,
  rsaEncryptionPKCS1,
  rsaEncryptionOAEPSHA224,
}

extension YKFPIVKeyAlgorithmValue on YKFPIVKeyAlgorithm {
  String get value {
    switch (this) {
      case YKFPIVKeyAlgorithm.ecdsaSignatureMessageX962SHA256:
        return "ecdsaSignatureMessageX962SHA256";
      case YKFPIVKeyAlgorithm.rsaSignatureMessagePKCS1v15SHA512:
        return "rsaSignatureMessagePKCS1v15SHA512";
      case YKFPIVKeyAlgorithm.rsaEncryptionPKCS1:
        return "rsaEncryptionPKCS1";
      case YKFPIVKeyAlgorithm.rsaEncryptionOAEPSHA224:
        return "rsaEncryptionOAEPSHA224";
    }
  }
}
