enum DataObject {
  aid,
  pwStatus,
  cardholderCertificate,
  attCertificate,
  kdf,
}

extension DataObjectValues on DataObject {
  int get value {
    switch (this) {
      case DataObject.aid:
        return 0x4F;
      case DataObject.pwStatus:
        return 0xC4;
      case DataObject.cardholderCertificate:
        return 0x7F21;
      case DataObject.attCertificate:
        return 0xFC;
      case DataObject.kdf:
        return 0xF9;
    }
  }
}
