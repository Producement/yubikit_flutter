//
//  YubikitFlutterPivHandler.swift
//  yubikit_flutter
//
//  Created by Maido Kaara on 06.05.2022.
//

import Foundation
import OSLog
import YubiKit

public class YubikitFlutterPivHandler {
    
    let logger = Logger()
    let yubiKeyConnection: YubiKeyConnection
    
    init(yubiKeyConnection: YubiKeyConnection) {
        self.yubiKeyConnection = yubiKeyConnection
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) -> Bool {
        func pivSession(completion: @escaping (_ session: YKFPIVSession)-> Void) {
            yubiKeyConnection.connection { connection in
                self.logger.info("Connection set up: \(connection.debugDescription!)")
                connection.pivSession { session, error in
                    self.logger.info("PIV session set up: \(session.debugDescription)")
                    guard let session = session else {
                        self.logger.error("Error! Reason: \(error!.localizedDescription)")
                        result(FlutterError(code: "session.error", message: "\(error!.localizedDescription)", details: ""))
                        return
                    }
                    completion(session)
                }
            }
        }
        
        func verifiedPinPivSession(pin: String, completion: @escaping (_ session: YKFPIVSession)-> Void) {
            pivSession { session in
                session.verifyPin(pin) { code, error in
                    if (error != nil) {
                        self.logger.info("PIN verification error: \(error.debugDescription)")
                        result(FlutterError(code: "pin.error", message: "\(error!.localizedDescription)", details: ""))
                        return
                    }
                    self.logger.info("PIN verification successful. Remaining attempts: \(code)")
                    completion(session)
                }
            }
        }
        
        func authenticatedPivSession(pin: String, managementKey: FlutterStandardTypedData, managementKeyType: NSNumber, completion: @escaping (_ session: YKFPIVSession)-> Void) {
            verifiedPinPivSession(pin: pin) { session in
                let pivManagementKey = YKFPIVManagementKeyType.fromValue(UInt8(truncating: managementKeyType))!
                session.authenticate(withManagementKey: managementKey.data, type: pivManagementKey) {error in
                    if (error != nil) {
                        self.logger.info("Authentication error: \(error.debugDescription)")
                        result(FlutterError(code: "authentication.error", message: "\(error!.localizedDescription)", details: ""))
                        return
                    }
                    completion(session)
                }
            }
        }
        
        func argument<T>(_ index: Int) -> T {
            return (call.arguments as! Array<Any>)[index] as! T
        }
        
        switch(call.method) {
        case "pivSerialNumber":
            pivSession { session in
                session.getSerialNumber { serialNumber, error in
                    if (error != nil) {
                        self.logger.info("Serial number error: \(error.debugDescription)")
                        result(FlutterError(code: "serialnumber.error", message: "\(error!.localizedDescription)", details: ""))
                        return
                    }
                    result(serialNumber)
                }
            }
        case "pivReset":
            pivSession { session in
                session.reset { error in
                    if (error != nil) {
                        self.logger.info("Reset error: \(error.debugDescription)")
                        result(FlutterError(code: "reset.error", message: "\(error!.localizedDescription)", details: ""))
                        return
                    }
                    result(nil)
                }
            }
        case "pivSetPin":
            pivSession { session in
                let pin: String  = argument(0)
                let oldPin: String  = argument(1)
                session.setPin(pin, oldPin:oldPin, completion: { error in
                    if (error != nil) {
                        self.logger.info("Change PIN error: \(error.debugDescription)")
                        result(FlutterError(code: "pin.error", message: "\(error!.localizedDescription)", details: ""))
                        return
                    }
                    result(nil)
                })
            }
        case "pivSetPuk":
            pivSession { session in
                let puk: String  = argument(0)
                let oldPuk: String  = argument(1)
                session.setPuk(puk, oldPuk:oldPuk, completion: { error in
                    if (error != nil) {
                        self.logger.info("Change PUK error: \(error.debugDescription)")
                        result(FlutterError(code: "puk.error", message: "\(error!.localizedDescription)", details: ""))
                        return
                    }
                    result(nil)
                })
            }
        case "pivGenerateKey":
            let slot: NSNumber  = argument(0)
            let keyType: NSNumber  = argument(1)
            let pinPolicy: NSNumber  = argument(2)
            let touchPolicy: NSNumber  = argument(3)
            let pin: String  = argument(4)
            let managementKeyType: NSNumber = argument(5)
            let managementKey: FlutterStandardTypedData = argument(6)
            authenticatedPivSession(pin: pin, managementKey: managementKey, managementKeyType: managementKeyType) { session in
                let pivSlot = YKFPIVSlot.init(rawValue: UInt(truncating: slot))!
                let pivKeyType = YKFPIVKeyType.init(rawValue: UInt(truncating: keyType))!
                let pivPinPolicy = YKFPIVPinPolicy.init(rawValue: UInt(truncating: pinPolicy))!
                let pivTouchPolicy = YKFPIVTouchPolicy.init(rawValue: UInt(truncating: touchPolicy))!
                session.generateKey(in: pivSlot, type: pivKeyType, pinPolicy: pivPinPolicy, touchPolicy: pivTouchPolicy, completion: { key, error in
                    guard let key = key else {
                        self.logger.error("Key error! Reason: \(error!.localizedDescription)")
                        result(FlutterError(code: "key.error", message: "\(error!.localizedDescription)", details: ""))
                        return
                    }
                    self.logger.info("Key generated")
                    let publicKey = SecKeyCopyPublicKey(key)!
                    result(SecKeyCopyExternalRepresentation(publicKey, nil))
                })
            }
        case "pivSignWithKey":
            let slot: NSNumber  = argument(0)
            let keyType: NSNumber  = argument(1)
            let algorithm: String  = argument(2)
            let pin: String  = argument(3)
            let message: FlutterStandardTypedData = argument(4)
            verifiedPinPivSession(pin: pin) { session in
                let pivSlot = YKFPIVSlot.init(rawValue: UInt(truncating: slot))!
                let pivKeyType = YKFPIVKeyType.init(rawValue: UInt(truncating: keyType))!
                let pivAlgorithm: SecKeyAlgorithm? = {
                    switch algorithm {
                        case "rsaSignatureMessagePKCS1v15SHA512": return SecKeyAlgorithm.rsaSignatureMessagePKCS1v15SHA512;
                        case "ecdsaSignatureMessageX962SHA256": return SecKeyAlgorithm.ecdsaSignatureMessageX962SHA256;
                        default: return nil;
                    }
                }()
                guard let pivAlgorithm = pivAlgorithm else {
                    result(FlutterError(code: "unsupported.algorithm.error", message: "Unsupported algorithm: \(algorithm)", details: ""))
                    return
                }
                self.logger.debug("Signing message: \(message.debugDescription) with key in slot: \(pivSlot.rawValue)")
                session.signWithKey(in: pivSlot, type: pivKeyType, algorithm: pivAlgorithm, message: message.data) { signature, error in
                    guard let signature = signature else {
                        self.logger.error("Failed to sign message: \(error!.localizedDescription)")
                        result(FlutterError(code: "sign.error", message: "\(error!.localizedDescription)", details: ""))
                        return
                    }
                    self.logger.info("Signature generated")
                    result(signature)
                }
            }
        case "pivDecryptWithKey":
            let slot: NSNumber  = argument(0)
            let algorithm: String  = argument(1)
            let pin: String  = argument(2)
            let message: FlutterStandardTypedData = argument(3)
            verifiedPinPivSession(pin: pin) { session in
                let pivSlot = YKFPIVSlot.init(rawValue: UInt(truncating: slot))!
                let pivAlgorithm: SecKeyAlgorithm? = {
                    switch algorithm {
                        case "rsaEncryptionPKCS1": return SecKeyAlgorithm.rsaEncryptionPKCS1;
                        case "rsaEncryptionOAEPSHA224": return SecKeyAlgorithm.rsaEncryptionOAEPSHA224;
                        default: return nil;
                    }
                }()
                guard let pivAlgorithm = pivAlgorithm else {
                    result(FlutterError(code: "unsupported.algorithm.error", message: "Unsupported algorithm: \(algorithm)", details: ""))
                    return
                }
                session.decryptWithKey(in: pivSlot, algorithm: pivAlgorithm, encrypted: message.data) { data, error in
                    guard let data = data else {
                        self.logger.error("Failed to decrypt message: \(error!.localizedDescription)")
                        result(FlutterError(code: "decrypt.error", message: "\(error!.localizedDescription)", details: ""))
                        return
                    }
                    result(data)
                }
            }
        case "pivCalculateSecretKey":
            let slot: NSNumber  = argument(0)
            let publicKey: FlutterStandardTypedData = argument(1)
            let pin: String  = argument(2)
            verifiedPinPivSession(pin: pin) { session in
                let pivSlot = YKFPIVSlot.init(rawValue: UInt(truncating: slot))!
                let attributes = [kSecAttrKeyType: kSecAttrKeyTypeEC, kSecAttrKeyClass: kSecAttrKeyClassPublic] as CFDictionary
                var error: Unmanaged<CFError>?
                let key = SecKeyCreateWithData(publicKey.data as CFData, attributes, &error)
                guard let key = key else {
                    self.logger.info("Key creation error: \(error.debugDescription)")
                    result(FlutterError(code: "key.error", message: "\(error.debugDescription)", details: ""))
                    return
                }
                session.calculateSecretKey(in: pivSlot, peerPublicKey: key) { data, error in
                    guard let data = data else {
                        self.logger.error("Failed to calculate secret key: \(error!.localizedDescription)")
                        result(FlutterError(code: "key.create.error", message: "\(error!.localizedDescription)", details: ""))
                        return
                    }
                    result(data)
                }
            }
        case "pivGetCertificate":
            let slot: NSNumber  = argument(0)
            let pin: String  = argument(1)
            verifiedPinPivSession(pin: pin) { session in
                let pivSlot = YKFPIVSlot.init(rawValue: UInt(truncating: slot))!
                session.getCertificateIn(pivSlot) { certificate, error in
                    guard let certificate = certificate else {
                        self.logger.error("Failed to get certificate: \(error!.localizedDescription)")
                        result(FlutterError(code: "certificate.get.error", message: "\(error!.localizedDescription)", details: ""))
                        return
                    }
                    let data = SecCertificateCopyData(certificate)
                    result(data)
                }
            }
        case "pivPutCertificate":
            let slot: NSNumber  = argument(0)
            let pin: String  = argument(1)
            let certificate: FlutterStandardTypedData = argument(2)
            let managementKeyType: NSNumber = argument(3)
            let managementKey: FlutterStandardTypedData = argument(4)
            authenticatedPivSession(pin: pin, managementKey: managementKey, managementKeyType: managementKeyType) { session in
                let pivSlot = YKFPIVSlot.init(rawValue: UInt(truncating: slot))!
                let pivCertificate = SecCertificateCreateWithData( nil, certificate.data as CFData)!
                session.putCertificate(pivCertificate, inSlot: pivSlot, completion: { error in
                    if (error != nil) {
                        self.logger.info("Failed to put certificate: \(error.debugDescription)")
                        result(FlutterError(code: "certificate.put.error", message: "\(error!.localizedDescription)", details: ""))
                        return
                    }
                    result(nil)
                })
            }
        case "pivEncryptWithKey":
            let keyType: NSNumber  = argument(0)
            let publicKey: FlutterStandardTypedData = argument(1)
            let message: FlutterStandardTypedData = argument(2)
            let pivKeyType = YKFPIVKeyType.init(rawValue: UInt(truncating: keyType))!
            var attrKeyType: CFString
            if (pivKeyType == YKFPIVKeyType.RSA2048 || pivKeyType == YKFPIVKeyType.RSA1024) {
                attrKeyType = kSecAttrKeyTypeRSA
            } else if(pivKeyType == YKFPIVKeyType.ECCP256 || pivKeyType == YKFPIVKeyType.ECCP384) {
                attrKeyType = kSecAttrKeyTypeEC
            } else {
                self.logger.info("Unknown key type: \(pivKeyType.rawValue)")
                result(FlutterError(code: "key.type.error", message: "Unknown key type: \(pivKeyType.rawValue)", details: ""))
                return true
            }
            let attributes = [kSecAttrKeyType: attrKeyType, kSecAttrKeyClass: kSecAttrKeyClassPublic] as CFDictionary
            var error: Unmanaged<CFError>?
            let key = SecKeyCreateWithData(publicKey.data as CFData, attributes, &error)
            guard let key = key else {
                self.logger.info("Key creation error: \(error.debugDescription)")
                result(FlutterError(code: "key.error", message: "\(error.debugDescription)", details: ""))
                return true
            }
            let keySize = SecKeyGetBlockSize(key)
            var encryptedBytes = [UInt8](repeating: 0, count: keySize)
            var outputSize : Int = keySize
            message.data.withUnsafeBytes { (unsafeBytes:UnsafeRawBufferPointer) in
                let bytes = unsafeBytes.bindMemory(to: UInt8.self).baseAddress!
                SecKeyEncrypt(key, SecPadding.PKCS1, bytes, Int(message.elementCount), &encryptedBytes, &outputSize)
            }
            result(Data(encryptedBytes))
        default:
            return false
        }
        return true
    }
}
