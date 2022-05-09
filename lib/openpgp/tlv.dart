import 'dart:typed_data';

class Tlv {
  int tag, offset, length, end;

  Tlv(this.tag, this.offset, this.length, this.end);

  factory Tlv.parse(List<int> data, {int offset = 0}) {
    int tag = data[offset];
    offset += 1;
    if (tag & 0x1F == 0x1F) {
      tag = tag << 8 | data[offset];
      offset += 1;
      while (tag & 0x80 == 0x80) {
        tag = tag << 8 | data[offset];
        offset += 1;
      }
    }
    int length = data[offset];
    offset += 1;
    late int end;

    if (length == 0x80) {
      end = offset;
      while (data[end] != 0x00 || data[end + 1] != 0x00) {
        end = Tlv.parse(data, offset: end).end;
        length = end - offset;
        end += 2;
      }
    } else {
      if (length > 0x80) {
        int numberOfBytes = length - 0x80;
        var blob = ByteData.sublistView(
            Uint8List.fromList(data.sublist(offset, offset + numberOfBytes)));
        length = blob.getInt32(0);
        offset += numberOfBytes;
      }
      end = offset + length;
    }

    return Tlv(tag, offset, length, end);
  }

  @override
  String toString() {
    return "Tlv(tag: ${tag.toRadixString(16)}, offset: $offset, length: $length, end: $end)";
  }
}

class TlvData {
  Map<int, Tlv> tlvData;
  Uint8List data;

  TlvData(this.tlvData, this.data);

  Uint8List getValue(int tag) {
    Tlv? tlv = tlvData[tag];
    if (tlv != null) {
      return data.sublist(tlv.offset, tlv.end);
    }
    return Uint8List(0);
  }

  TlvData get(int tag) {
    return TlvData.parse(getValue(tag));
  }

  factory TlvData.parse(Uint8List data) {
    Map<int, Tlv> parsedData = {};
    int offset = 0;
    while (offset < data.length) {
      var tlv = Tlv.parse(data, offset: offset);
      parsedData[tlv.tag] = tlv;
      offset = tlv.end;
    }
    return TlvData(parsedData, data);
  }

  @override
  String toString() {
    return "TlvData(tlvData: $tlvData, data: $data)";
  }
}
