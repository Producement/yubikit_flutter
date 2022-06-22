//
//  Tlv.swift
//  yubikit_flutter
//
//  Created by Maido Kaara on 20.06.2022.
//

import Foundation

class TlvData {
    let tlvData: [UInt16: Tlv]
    let data: [UInt8]

    init(data: [UInt8]) {
        var parsedData: [UInt16: Tlv] = [:]
        var offset = 0
        while offset < data.count {
            let tlv = Tlv.parse(data: data, offset: offset)
            parsedData[tlv.tag] = tlv
            offset = tlv.end
        }
        self.tlvData = parsedData
        self.data = data
    }

    func get(tag: UInt16) -> TlvData {
        return TlvData(data: getValue(tag: tag))
    }

    func getValue(tag: UInt16) -> [UInt8] {
        let tlv = tlvData[tag]
        guard tlv != nil else {
            return []
        }
        return Array(data[tlv!.offset..<tlv!.end])
    }
}

class Tlv {
    let tag: UInt16
    let offset, length, end: Int

    init(tag: UInt16, offset: Int, length: Int, end: Int) {
        self.tag = tag
        self.offset = offset
        self.length = length
        self.end = end
    }

    static func parse(data: [UInt8], offset: Int) -> Tlv {
        var tag: UInt16 = UInt16(data[offset])
        var offset = offset + 1
        if tag & 0x1f == 0x1f {
            tag = tag << 8 | UInt16(data[offset])
            offset += 1
            while tag & 0x80 == 0x80 {
                tag = tag << 8 | UInt16(data[offset])
                offset += 1
            }
        }
        var length: Int = Int(data[offset])
        offset = offset + 1
        var end: Int

        if length == 0x80 {
            end = offset
            while data[end] != 0x00 || data[end + 1] != 0x00 {
                end = Tlv.parse(data: data, offset: end).end
                length = end - offset
                end += 2
            }
        } else {
            if length > 0x80 {
                let numberOfBytes = length - 0x80
                let blob = data[offset...offset + numberOfBytes]
                let value = blob.withUnsafeBufferPointer {
                    ($0.baseAddress!.withMemoryRebound(to: UInt16.self, capacity: 1) { $0 })
                }.pointee
                length = Int(UInt16(bigEndian: value))
                offset = offset + numberOfBytes
            }
            end = offset + length
        }
        return Tlv(tag: tag, offset: offset, length: length, end: end)
    }
}
