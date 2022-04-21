import Flutter
import UIKit
import Foundation
import OSLog
import YubiKit

public class SwiftYubikitFlutterPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "yubikit_flutter", binaryMessenger: registrar.messenger())
        let instance = SwiftYubikitFlutterPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    let logger = Logger()
    var connection: YubiKeyConnection?
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch(call.method) {
        case "connect":
            logger.info("Setting up Yubikey connection")
            if(connection != nil) {
                logger.info("Connection already made!")
                result(FlutterError(code: "connection.active", message: "Connection already made!", details: "Only one connection allowed at a time"))
                return
            }
            connection = YubiKeyConnection();
            result(nil)
        case "disconnect":
            logger.info("Disconnecting")
            connection = nil
            result(nil)
        case "pivSignWithKey":
            guard let connection = connection else {
                result(FlutterError(code: "connection.not.active", message: "Connection not made!", details: "Connect before calling any methods"))
                return
            }
            connection.connection { connection in
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
                                self.connection?.nfcConnection?.stop()
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
            guard let connection = connection else {
                result(FlutterError(code: "connection.not.active", message: "Connection not made!", details: "Connect before calling any methods"))
                return
            }
            connection.connection { connection in
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
                                self.connection?.nfcConnection?.stop()
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
        case "pivGetPublicKey":
            guard let connection = connection else {
                result(FlutterError(code: "connection.not.active", message: "Connection not made!", details: "Connect before calling any methods"))
                return
            }
            connection.connection { connection in
                self.logger.info("Connection set up: \(connection.debugDescription!)")
                connection.pivSession { session, error in
                    self.logger.info("PIV session set up: \(session.debugDescription)")
                    guard let session = session else {
                        self.logger.error("Session error! Reason: \(error!.localizedDescription)")
                        result(FlutterError(code: "session.error", message: "\(error!.localizedDescription)", details: ""))
                        return
                    }
                    let slot  = (call.arguments as! Array<Any>)[0] as! NSNumber
                    let pivSlot = YKFPIVSlot.init(rawValue: UInt(truncating: slot))!
                    self.logger.debug("Getting certificate from key in slot: \(pivSlot.rawValue)")
                    session.getCertificateIn(pivSlot) { certificate, error in
                        defer {
                            self.connection?.nfcConnection?.stop()
                        }
                        guard let certificate = certificate else {
                            self.logger.error("Certificate error! Reason: \(error!.localizedDescription)")
                            result(FlutterError(code: "certificate.error", message: "\(error!.localizedDescription)", details: ""))
                            return
                        }
                        let publicKey = SecCertificateCopyKey(certificate)
                        result(SecKeyCopyExternalRepresentation(publicKey!, nil))
                    }
                }
            }
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}
