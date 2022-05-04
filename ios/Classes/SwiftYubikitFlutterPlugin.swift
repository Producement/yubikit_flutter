import Flutter
import UIKit
import Foundation
import OSLog
import YubiKit
import Security

public class SwiftYubikitFlutterPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "yubikit_flutter", binaryMessenger: registrar.messenger())
        let instance = SwiftYubikitFlutterPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    let logger = Logger()
    let yubiKeyConnection = YubiKeyConnection()
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let conn = YubiKeyConnection()
        switch(call.method) {
        case "pivReset":
            yubiKeyConnection.connection { connection in
                self.logger.info("Connection set up: \(connection.debugDescription!)")
                connection.pivSession { session, error in
                    guard let session = session else {
                        self.logger.error("Error! Reason: \(error!.localizedDescription)")
                        result(FlutterError(code: "session.error", message: "\(error!.localizedDescription)", details: ""))
                        return
                    }
                    session.reset { error in
                        defer {
                            self.logger.info("Closing NFC connection")
                            conn.nfcConnection?.stop()
                        }
                        if (error != nil) {
                            self.logger.info("Reset error: \(error.debugDescription)")
                            result(FlutterError(code: "reset.error", message: "\(error!.localizedDescription)", details: ""))
                            return
                        }
                        result(nil)
                    }
                }
            }
        case "pivSetPin":
            yubiKeyConnection.connection { connection in
                self.logger.info("Connection set up: \(connection.debugDescription!)")
                connection.pivSession { session, error in
                    self.logger.info("PIV session set up: \(session.debugDescription)")
                    guard let session = session else {
                        self.logger.error("Error! Reason: \(error!.localizedDescription)")
                        result(FlutterError(code: "session.error", message: "\(error!.localizedDescription)", details: ""))
                        return
                    }
                    let pin  = (call.arguments as! Array<Any>)[0] as! String
                    let oldPin  = (call.arguments as! Array<Any>)[1] as! String
                    session.setPin(pin, oldPin:oldPin, completion: { error in
                        defer {
                            self.logger.info("Closing NFC connection")
                            conn.nfcConnection?.stop()
                        }
                        if (error != nil) {
                            self.logger.info("Change PIN error: \(error.debugDescription)")
                            result(FlutterError(code: "pin.error", message: "\(error!.localizedDescription)", details: ""))
                            return
                        }
                        result(nil)
                    })
                }
            }
        case "pivSetPuk":
            yubiKeyConnection.connection { connection in
                self.logger.info("Connection set up: \(connection.debugDescription!)")
                connection.pivSession { session, error in
                    self.logger.info("PIV session set up: \(session.debugDescription)")
                    guard let session = session else {
                        self.logger.error("Error! Reason: \(error!.localizedDescription)")
                        result(FlutterError(code: "session.error", message: "\(error!.localizedDescription)", details: ""))
                        return
                    }
                    let puk  = (call.arguments as! Array<Any>)[0] as! String
                    let oldPuk  = (call.arguments as! Array<Any>)[1] as! String
                    session.setPuk(puk, oldPuk:oldPuk, completion: { error in
                        defer {
                            self.logger.info("Closing NFC connection")
                            conn.nfcConnection?.stop()
                        }
                        if (error != nil) {
                            self.logger.info("Change PUK error: \(error.debugDescription)")
                            result(FlutterError(code: "puk.error", message: "\(error!.localizedDescription)", details: ""))
                            return
                        }
                        result(nil)
                    })
                }
            }
        case "pivGenerateKey":
            yubiKeyConnection.connection { connection in
                self.logger.info("Connection set up: \(connection.debugDescription!)")
                connection.pivSession { session, error in
                    self.logger.info("PIV session set up: \(session.debugDescription)")
                    guard let session = session else {
                        self.logger.error("Error! Reason: \(error!.localizedDescription)")
                        result(FlutterError(code: "session.error", message: "\(error!.localizedDescription)", details: ""))
                        return
                    }
                    let slot  = (call.arguments as! Array<Any>)[0] as! NSNumber
                    let keyType  = (call.arguments as! Array<Any>)[1] as! NSNumber
                    let pinPolicy  = (call.arguments as! Array<Any>)[2] as! NSNumber
                    let touchPolicy  = (call.arguments as! Array<Any>)[3] as! NSNumber
                    let pin  = (call.arguments as! Array<Any>)[4] as! String
                    let managementKeyType = (call.arguments as! Array<Any>)[5] as! NSNumber
                    let managementKey = (call.arguments as! Array<Any>)[6] as! FlutterStandardTypedData
                    session.verifyPin(pin) { code, error in
                        if (error != nil) {
                            self.logger.info("PIN verification error: \(error.debugDescription)")
                            result(FlutterError(code: "pin.error", message: "\(error!.localizedDescription)", details: ""))
                            return
                        }
                        self.logger.info("PIN verification successful. Remaining attempts: \(code)")
                        let pivManagementKey = YKFPIVManagementKeyType.fromValue(UInt8(truncating: managementKeyType))!
                        session.authenticate(withManagementKey: managementKey.data, type: pivManagementKey) {error in
                            if (error != nil) {
                                self.logger.info("Authentication error: \(error.debugDescription)")
                                result(FlutterError(code: "authentication.error", message: "\(error!.localizedDescription)", details: ""))
                                return
                            }
                            let pivSlot = YKFPIVSlot.init(rawValue: UInt(truncating: slot))!
                            let pivKeyType = YKFPIVKeyType.init(rawValue: UInt(truncating: keyType))!
                            let pivPinPolicy = YKFPIVPinPolicy.init(rawValue: UInt(truncating: pinPolicy))!
                            let pivTouchPolicy = YKFPIVTouchPolicy.init(rawValue: UInt(truncating: touchPolicy))!
                            session.generateKey(in: pivSlot, type: pivKeyType, pinPolicy: pivPinPolicy, touchPolicy: pivTouchPolicy, completion: { key, error in
                                defer {
                                    self.logger.info("Closing NFC connection")
                                    conn.nfcConnection?.stop()
                                }
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
                    }
                }
            }
        case "pivSignWithKey":
            yubiKeyConnection.connection { connection in
                self.logger.info("Connection set up: \(connection.debugDescription!)")
                connection.pivSession { session, error in
                    self.logger.info("PIV session set up: \(session.debugDescription)")
                    guard let session = session else {
                        self.logger.error("Error! Reason: \(error!.localizedDescription)")
                        result(FlutterError(code: "session.error", message: "\(error!.localizedDescription)", details: ""))
                        return
                    }
                    let slot  = (call.arguments as! Array<Any>)[0] as! NSNumber
                    let keyType  = (call.arguments as! Array<Any>)[1] as! NSNumber
                    let algorithm  = (call.arguments as! Array<Any>)[2] as! String
                    let pin  = (call.arguments as! Array<Any>)[3] as! String
                    session.verifyPin(pin) { code, error in
                        if (error != nil) {
                            self.logger.info("PIN verification error: \(error.debugDescription)")
                            result(FlutterError(code: "pin.error", message: "\(error!.localizedDescription)", details: ""))
                            return
                        }
                        self.logger.info("PIN verification successful. Remaining attempts: \(code)")
                        let message = (call.arguments as! Array<Any>)[4] as! FlutterStandardTypedData
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
                            defer {
                                self.logger.info("Closing NFC connection")
                                conn.nfcConnection?.stop()
                            }
                            guard let signature = signature else {
                                self.logger.error("Failed to sign message: \(error!.localizedDescription)")
                                result(FlutterError(code: "sign.error", message: "\(error!.localizedDescription)", details: ""))
                                return
                            }
                            self.logger.info("Signature generated")
                            result(signature)
                        }
                        
                    }
                }
            }
        case "pivDecryptWithKey":
            yubiKeyConnection.connection { connection in
                self.logger.info("Connection set up: \(connection.debugDescription!)")
                connection.pivSession { session, error in
                    self.logger.info("PIV session set up: \(session.debugDescription)")
                    guard let session = session else {
                        self.logger.error("Error! Reason: \(error!.localizedDescription)")
                        result(FlutterError(code: "session.error", message: "\(error!.localizedDescription)", details: ""))
                        return
                    }
                    let slot  = (call.arguments as! Array<Any>)[0] as! NSNumber
                    let algorithm  = (call.arguments as! Array<Any>)[1] as! String
                    let pin  = (call.arguments as! Array<Any>)[2] as! String
                    session.verifyPin(pin) { code, error in
                        if (error != nil) {
                            self.logger.info("PIN verification error: \(error.debugDescription)")
                            result(FlutterError(code: "pin.error", message: "\(error!.localizedDescription)", details: ""))
                            return
                        }
                        self.logger.info("PIN verification successful. Remaining attempts: \(code)")
                        let message = (call.arguments as! Array<Any>)[3] as! FlutterStandardTypedData
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
                            defer {
                                conn.nfcConnection?.stop()
                            }
                            guard let data = data else {
                                self.logger.error("Failed to decrypt message: \(error!.localizedDescription)")
                                result(FlutterError(code: "decrypt.error", message: "\(error!.localizedDescription)", details: ""))
                                return
                            }
                            result(data)
                        }
                    }
                }
            }
        case "pivCalculateSecretKey":
            yubiKeyConnection.connection { connection in
                self.logger.info("Connection set up: \(connection.debugDescription!)")
                connection.pivSession { session, error in
                    self.logger.info("PIV session set up: \(session.debugDescription)")
                    guard let session = session else {
                        self.logger.error("Error! Reason: \(error!.localizedDescription)")
                        result(FlutterError(code: "session.error", message: "\(error!.localizedDescription)", details: ""))
                        return
                    }
                    let slot  = (call.arguments as! Array<Any>)[0] as! NSNumber
                    let publicKey = (call.arguments as! Array<Any>)[1] as! FlutterStandardTypedData
                    let pin  = (call.arguments as! Array<Any>)[2] as! String
                    let managementKeyType = (call.arguments as! Array<Any>)[3] as! NSNumber
                    let managementKey = (call.arguments as! Array<Any>)[4] as! FlutterStandardTypedData
                    session.verifyPin(pin) { code, error in
                        if (error != nil) {
                            self.logger.info("PIN verification error: \(error.debugDescription)")
                            result(FlutterError(code: "pin.error", message: "\(error!.localizedDescription)", details: ""))
                            return
                        }
                        self.logger.info("PIN verification successful. Remaining attempts: \(code)")
                        let pivManagementKey = YKFPIVManagementKeyType.fromValue(UInt8(truncating: managementKeyType))!
                        session.authenticate(withManagementKey: managementKey.data, type: pivManagementKey) {error in
                            if (error != nil) {
                                self.logger.info("Authentication error: \(error.debugDescription)")
                                result(FlutterError(code: "authentication.error", message: "\(error!.localizedDescription)", details: ""))
                                return
                            }
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
                                defer {
                                    conn.nfcConnection?.stop()
                                }
                                guard let data = data else {
                                    self.logger.error("Failed to calculate secret key: \(error!.localizedDescription)")
                                    result(FlutterError(code: "key.create.error", message: "\(error!.localizedDescription)", details: ""))
                                    return
                                }
                                result(data)
                            }
                        }
                }
            }
        }
        case "pivGetCertificate":
            yubiKeyConnection.connection { connection in
                self.logger.info("Connection set up: \(connection.debugDescription!)")
                connection.pivSession { session, error in
                    self.logger.info("PIV session set up: \(session.debugDescription)")
                    guard let session = session else {
                        self.logger.error("Error! Reason: \(error!.localizedDescription)")
                        result(FlutterError(code: "session.error", message: "\(error!.localizedDescription)", details: ""))
                        return
                    }
                    let slot  = (call.arguments as! Array<Any>)[0] as! NSNumber
                    let pin  = (call.arguments as! Array<Any>)[1] as! String
                    session.verifyPin(pin) { code, error in
                        if (error != nil) {
                            self.logger.info("PIN verification error: \(error.debugDescription)")
                            result(FlutterError(code: "pin.error", message: "\(error!.localizedDescription)", details: ""))
                            return
                        }
                        self.logger.info("PIN verification successful. Remaining attempts: \(code)")
                        let pivSlot = YKFPIVSlot.init(rawValue: UInt(truncating: slot))!
                        session.getCertificateIn(pivSlot){ certificate, error in
                            defer {
                                conn.nfcConnection?.stop()
                            }
                            guard let certificate = certificate else {
                                self.logger.error("Failed to get certificate: \(error!.localizedDescription)")
                                result(FlutterError(code: "certificate.get.error", message: "\(error!.localizedDescription)", details: ""))
                                return
                            }
                            let data = SecCertificateCopyData(certificate)
                            result(data)
                        }
                    }
                }
            }
        case "pivPutCertificate":
            yubiKeyConnection.connection { connection in
                self.logger.info("Connection set up: \(connection.debugDescription!)")
                connection.pivSession { session, error in
                    self.logger.info("PIV session set up: \(session.debugDescription)")
                    guard let session = session else {
                        self.logger.error("Error! Reason: \(error!.localizedDescription)")
                        result(FlutterError(code: "session.error", message: "\(error!.localizedDescription)", details: ""))
                        return
                    }
                    let slot  = (call.arguments as! Array<Any>)[0] as! NSNumber
                    let pin  = (call.arguments as! Array<Any>)[1] as! String
                    let certificate = (call.arguments as! Array<Any>)[2] as! FlutterStandardTypedData
                    let managementKeyType = (call.arguments as! Array<Any>)[3] as! NSNumber
                    let managementKey = (call.arguments as! Array<Any>)[4] as! FlutterStandardTypedData
                    session.verifyPin(pin) { code, error in
                        if (error != nil) {
                            self.logger.info("PIN verification error: \(error.debugDescription)")
                            result(FlutterError(code: "pin.error", message: "\(error!.localizedDescription)", details: ""))
                            return
                        }
                        self.logger.info("PIN verification successful. Remaining attempts: \(code)")
                        let pivManagementKey = YKFPIVManagementKeyType.fromValue(UInt8(truncating: managementKeyType))!
                        session.authenticate(withManagementKey: managementKey.data, type: pivManagementKey) {error in
                            if (error != nil) {
                                self.logger.info("Authentication error: \(error.debugDescription)")
                                result(FlutterError(code: "authentication.error", message: "\(error!.localizedDescription)", details: ""))
                                return
                            }
                            let pivSlot = YKFPIVSlot.init(rawValue: UInt(truncating: slot))!
                            let pivCertificate = SecCertificateCreateWithData( nil, certificate.data as CFData)!
                            session.putCertificate(pivCertificate, inSlot: pivSlot, completion: { error in
                                defer {
                                    conn.nfcConnection?.stop()
                                }
                                if (error != nil) {
                                    self.logger.info("Failed to put certificate: \(error.debugDescription)")
                                    result(FlutterError(code: "certificate.put.error", message: "\(error!.localizedDescription)", details: ""))
                                    return
                                }
                                result(nil)
                            })
                        }
                    }
                }
            }
        case "pivEncryptWithKey":
            let publicKey = (call.arguments as! Array<Any>)[0] as! FlutterStandardTypedData
            let message = (call.arguments as! Array<Any>)[1] as! FlutterStandardTypedData
            let attributes = [kSecAttrKeyType: kSecAttrKeyTypeRSA, kSecAttrKeyClass: kSecAttrKeyClassPublic] as CFDictionary
            var error: Unmanaged<CFError>?
            let key = SecKeyCreateWithData(publicKey.data as CFData, attributes, &error)
            guard let key = key else {
                self.logger.info("Key creation error: \(error.debugDescription)")
                result(FlutterError(code: "key.error", message: "\(error.debugDescription)", details: ""))
                return
            }
            let key_size = SecKeyGetBlockSize(key)
            var encrypt_bytes = [UInt8](repeating: 0, count: key_size)
            var output_size : Int = key_size
            message.data.withUnsafeBytes { (unsafeBytes:UnsafeRawBufferPointer) in
                let bytes = unsafeBytes.bindMemory(to: UInt8.self).baseAddress!
                SecKeyEncrypt(key, SecPadding.PKCS1, bytes, Int(message.elementCount), &encrypt_bytes, &output_size)
            }
            result(Data(encrypt_bytes))
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
