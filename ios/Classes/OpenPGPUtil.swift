//
//  OpenPGPUtil.swift
//  yubikit_flutter
//
//  Created by Maido Kaara on 20.06.2022.
//

import Foundation
import CryptoKit

func parseECPublicKey(response: Data) -> Data {
    let data = TlvData(data: response.bytes).get(tag: 0x7F49)
    let publicKey = data.getValue(tag: 0x86)
    return Data(publicKey)
}

func parseRSAPublicKey(response: Data) -> (modulus: Data, exponent: Data) {
    let data = TlvData(data: response.bytes).get(tag: 0x7F49)
    let modulus = data.getValue(tag: 0x81)
    let exponent = data.getValue(tag: 0x82)
    return (Data(modulus), Data(exponent))
}

func setRSAKeyFingerpint(modulus: Data, exponent: Data, timestamp: Int32) -> Data {
    var encoded = Data()
    encoded.append(contentsOf: timestampAndVersion(timestamp: timestamp))
    encoded.append(contentsOf: mpi(modulus))
    encoded.append(contentsOf: mpi(exponent))
    var response = Data([0x99])
    response.append(contentsOf: mpi(encoded))
    return Data(Insecure.SHA1.hash(data: response))
}

func setECKeyFingerpint(publicKey: Data, curveParameters: Data, timestamp: Int32) -> Data {
    var encoded = Data()
    encoded.append(contentsOf: timestampAndVersion(timestamp: timestamp))
    encoded.append(contentsOf: curveParameters)
    encoded.append(contentsOf: keyMaterial(publicKey))
    var response = Data([0x99])
    response.append(contentsOf: mpi(encoded))
    return Data(Insecure.SHA1.hash(data: response))
}

func keyMaterial(_ data: Data) -> Data {
    let length = Int16(data.count * 8 - 1)
    var response = Data(withUnsafeBytes(of: length.bigEndian, Array.init))
    response.append(contentsOf: data)
    return response
}

func mpi(_ data: Data) -> Data {
    let length = Int16(data.count)
    var response = Data(withUnsafeBytes(of: length.bigEndian, Array.init))
    response.append(contentsOf: data)
    return response
}

func timestampAndVersion(timestamp: Int32) -> Data {
    let timestampBytes = Data(withUnsafeBytes(of: timestamp.bigEndian, Array.init))
    var response = Data([0x04])
    response.append(contentsOf: timestampBytes)
    return response
}

func setGenerationTime(timestamp: Int32) -> Data {
    return Data(withUnsafeBytes(of: timestamp.bigEndian, Array.init))
}
