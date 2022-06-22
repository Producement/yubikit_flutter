//
//  YubikitFlutterOpenPGPHandler.swift
//  yubikit_flutter
//
//  Created by Maido Kaara on 20.06.2022.
//

import CryptoKit
import Foundation
import OSLog
import YubiKit

public class YubikitFlutterOpenPGPHandler: NSObject, FlutterPlugin {
    
    static let logger = Logger()
    let openPGPApplication = Data(base64Encoded: "0nYAASQB")!
    let yubiKeyConnection: YubiKeyConnection
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        logger.info("Registering OpenPGP handler")
        let smartCardChannel = FlutterMethodChannel(name: "yubikit_flutter_pgp", binaryMessenger: registrar.messenger())
        let smartCardHandler = YubikitFlutterOpenPGPHandler(yubiKeyConnection: YubiKeyConnection.shared)
        registrar.addMethodCallDelegate(smartCardHandler, channel: smartCardChannel)
    }
    
    init(yubiKeyConnection: YubiKeyConnection) {
        self.yubiKeyConnection = yubiKeyConnection
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        YubikitFlutterOpenPGPHandler.logger.info("Handling call: \(call.method)")
        @Sendable func sendResult(_ res: Any) {
            yubiKeyConnection.stop()
            result(res)
        }
        
        @Sendable func handleError(error: Error?) {
            YubikitFlutterOpenPGPHandler.logger.error("Error! Reason: \(error!.localizedDescription)")
            if let scError = error as? YKFSessionError {
                sendResult(FlutterError(code: "yubikit.smartcard.error", message: "\(scError.localizedDescription)", details: scError.code))
            } else if let ykError = error as? YubikitFlutterError {
                sendResult(FlutterError(code: ykError.code, message: ykError.message, details: ykError.details))
            } else {
                sendResult(FlutterError(code: "yubikit.error", message: "\(error!.localizedDescription)", details: nil))
            }
        }
        
        switch call.method {
            case "generateECAsymmetricKey":
                let keyAttributesCommands: [FlutterStandardTypedData] = call.argument(0)
                let generateAsymmetricKeyCommands: [FlutterStandardTypedData] = call.argument(1)
                let curveParameters: [FlutterStandardTypedData] = call.argument(2)
                let keySlots: [Int32] = call.argument(3)
                let genTimes: [Int32] = call.argument(4)
                let verify: FlutterStandardTypedData = call.argument(5)
                yubiKeyConnection.connection { connection, error in
                    guard let connection = connection else {
                        handleError(error: error!)
                        return
                    }
                    guard let smartCardInterface = connection.smartCardInterface else {
                        YubikitFlutterOpenPGPHandler.logger.error("Smart card interface not present!")
                        sendResult(FlutterError(code: "yubikit.error", message: "Smart card not present", details: nil))
                        return
                    }
                    Task {
                        do {
                            try await smartCardInterface.selectApp(application: self.openPGPApplication)
                            try await smartCardInterface.verifyPin(verify: verify.data)
                            var responses: [Data] = []
                            for i in 0..<keyAttributesCommands.count {
                                let keyAttributesCommand = keyAttributesCommands[i]
                                let generateAsymmetricKeyCommand = generateAsymmetricKeyCommands[i]
                                let curveParameter = curveParameters[i]
                                let keySlot = keySlots[i]
                                let genTime = genTimes[i]
                                let response = try await smartCardInterface.generateECAsymmetricKey(keyAttributesCommand: keyAttributesCommand.data, generateAsymmetricKeyCommand: generateAsymmetricKeyCommand.data, curveParameters: curveParameter.data, keySlot: Int16(keySlot), genTime: Int16(genTime))
                                responses.append(response)
                            }
                            sendResult(responses)
                        } catch {
                            handleError(error: error)
                        }
                    }
                }
            case "generateRSAAsymmetricKey":
                let keyAttributesCommands: [FlutterStandardTypedData] = call.argument(0)
                let generateAsymmetricKeyCommands: [FlutterStandardTypedData] = call.argument(1)
                let keySlots: [Int32] = call.argument(2)
                let genTimes: [Int32] = call.argument(3)
                let verify: FlutterStandardTypedData = call.argument(4)
                yubiKeyConnection.connection { connection, error in
                    guard let connection = connection else {
                        handleError(error: error!)
                        return
                    }
                    guard let smartCardInterface = connection.smartCardInterface else {
                        YubikitFlutterOpenPGPHandler.logger.error("Smart card interface not present!")
                        sendResult(FlutterError(code: "yubikit.error", message: "Smart card not present", details: nil))
                        return
                    }
                    Task {
                        do {
                            try await smartCardInterface.selectApp(application: self.openPGPApplication)
                            try await smartCardInterface.verifyPin(verify: verify.data)
                            var responses: [Data] = []
                            for i in 0..<keyAttributesCommands.count {
                                let keyAttributesCommand = keyAttributesCommands[i]
                                let generateAsymmetricKeyCommand = generateAsymmetricKeyCommands[i]
                                let keySlot = keySlots[i]
                                let genTime = genTimes[i]
                                let response = try await smartCardInterface.generateRSAAsymmetricKey(keyAttributesCommand: keyAttributesCommand.data, generateAsymmetricKeyCommand: generateAsymmetricKeyCommand.data, keySlot: Int16(keySlot), genTime: Int16(genTime))
                                responses.append(response)
                            }
                            sendResult(responses)
                        } catch {
                            handleError(error: error)
                        }
                    }
                }
            default:
                result(FlutterMethodNotImplemented)
        }
    }
}
    
