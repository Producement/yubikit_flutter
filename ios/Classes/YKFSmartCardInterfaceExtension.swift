//
//  YKFSmartCardInterfaceExtension.swift
//  yubikit_flutter
//
//  Created by Maido Kaara on 20.06.2022.
//

import Foundation
import YubiKit

extension YKFSmartCardInterface {
    
    @Sendable func generateECAsymmetricKey(keyAttributesCommand: Data, generateAsymmetricKeyCommand: Data, curveParameters: Data, keySlot: Int16, genTime: Int16) async throws -> Data {
        let _ = try await runCommand(data: keyAttributesCommand)
        let response = try await runCommand(data: generateAsymmetricKeyCommand)
        let publicKey = parseECPublicKey(response: response)
        let timestamp = Int32(NSDate().timeIntervalSince1970)
        let setFingerprint = setECKeyFingerpint(publicKey: publicKey, curveParameters: curveParameters, timestamp: timestamp)
        let _ = try await putData(command: Int16(keySlot), data: setFingerprint)
        let setGenerationTime = setGenerationTime(timestamp: timestamp)
        let _ = try await putData(command: Int16(genTime), data: setGenerationTime)
        return response
    }
    
    @Sendable func generateRSAAsymmetricKey(keyAttributesCommand: Data, generateAsymmetricKeyCommand: Data, keySlot: Int16, genTime: Int16) async throws -> Data{
        let _ = try await runCommand(data: keyAttributesCommand)
        let response = try await runCommand(data: generateAsymmetricKeyCommand)
        let publicKey = parseRSAPublicKey(response: response)
        let timestamp = Int32(NSDate().timeIntervalSince1970)
        let setFingerprint = setRSAKeyFingerpint(modulus: publicKey.modulus, exponent: publicKey.exponent, timestamp: timestamp)
        let _ = try await putData(command: Int16(keySlot), data: setFingerprint)
        let setGenerationTime = setGenerationTime(timestamp: timestamp)
        let _ = try await putData(command: Int16(genTime), data: setGenerationTime)
        return response
    }
    
    @Sendable func putData(command: Int16, data: Data) async throws -> Data {
        let params = Data(withUnsafeBytes(of: command.bigEndian, Array.init))
        return try await executeCommand(YKFAPDU(cla: 0x00, ins: 0xDA, p1: params[0], p2: params[1], data: data, type: YKFAPDUType.short)!)
    }
    
    @Sendable func runCommand(data: Data) async throws -> Data {
        let result: Data = try await withCheckedThrowingContinuation { continuation in
            executeCommand(YKFAPDU(data: data)!, completion: { data, error in
                guard let data = data else {
                    continuation.resume(throwing: error!)
                    return
                }
                continuation.resume(returning: data)
            })
        }
        return result
    }
    
    @Sendable func verifyPin(verify: Data) async throws {
        let _: Data = try await withCheckedThrowingContinuation { continuation in
            executeCommand(YKFAPDU(data: verify)!, completion: { verifyData, error in
                if verifyData != nil {
                    continuation.resume(returning: verifyData!)
                } else {
                    continuation.resume(throwing: error!)
                }
            })
        }
    }
    
    @Sendable func runCommands(commands: NSArray, verify: Data?) async throws -> [Data] {
        if !(verify?.isEmpty ?? true) {
            try await verifyPin(verify: verify!)
        }
        var results: [Data] = []
        for command in commands {
            do {
                if let cmd = command as? FlutterStandardTypedData {
                    let response = try await runCommand(data: cmd.data)
                    results.append(response)
                }
            } catch {
                if let scError = error as? YKFSessionError {
                    results.append(Data(withUnsafeBytes(of: Int16(scError.code).bigEndian, Array.init)))
                } else {
                    throw error
                }
            }
        }
        return results
    }
    
    @Sendable func selectApp(application: Data) async throws {
        let _: Void = try await withCheckedThrowingContinuation { continuation in
            guard let applicationApdu = YKFSelectApplicationAPDU(cla: 0x00, ins: 0xa4, p1: 0x04, p2: 0x00, data: application, type: .short) else {
                continuation.resume(throwing: YubikitFlutterError(code: "yubikit.error", message: "Application APDU invalid", details: nil))
                return
            }
            selectApplication(applicationApdu) { _, error in
                if error != nil {
                    guard let activateApdu = YKFAPDU(cla: 0x00, ins: 0x44, p1: 0x00, p2: 0x00, data: Data(), type: .short) else {
                        continuation.resume(throwing: YubikitFlutterError(code: "yubikit.error", message: "Activate APDU invalid", details: ""))
                        return
                    }
                    self.executeCommand(activateApdu, completion: { _, error in
                        if error != nil {
                            continuation.resume(throwing: error!)
                            return
                        }
                        self.selectApplication(applicationApdu) { _, error in
                            if error != nil {
                                continuation.resume(throwing: error!)
                                return
                            }
                            continuation.resume()
                        }
                    })
                } else {
                    continuation.resume()
                }
            }
        }
    }
}

class YubikitFlutterError: LocalizedError {
    let code: String
    let message: String
    let details: String?
    
    init(code: String, message: String, details: String?) {
        self.code = code
        self.message = message
        self.details = details
    }
}
