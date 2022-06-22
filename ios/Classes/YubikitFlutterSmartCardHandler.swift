//
//  YubikitFlutterSmartCardHandler.swift
//  yubikit_flutter
//
//  Created by Maido Kaara on 06.05.2022.
//

import Flutter
import Foundation
import OSLog
import YubiKit

public class YubikitFlutterSmartCardHandler: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let smartCardChannel = FlutterMethodChannel(name: "yubikit_flutter_sc", binaryMessenger: registrar.messenger())
        let smartCardHandler = YubikitFlutterSmartCardHandler(yubiKeyConnection: YubiKeyConnection.shared)
        registrar.addMethodCallDelegate(smartCardHandler, channel: smartCardChannel)
    }
    
    let logger = Logger()
    let yubiKeyConnection: YubiKeyConnection
    
    init(yubiKeyConnection: YubiKeyConnection) {
        self.yubiKeyConnection = yubiKeyConnection
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        @Sendable func sendResult(_ res: Any) {
            yubiKeyConnection.stop()
            result(res)
        }
        
        @Sendable func handleError(error: Error?) {
            logger.error("Error! Reason: \(error!.localizedDescription)")
            if let scError = error as? YKFSessionError {
                sendResult(FlutterError(code: "yubikit.smartcard.error", message: "\(scError.localizedDescription)", details: scError.code))
            } else if let ykError = error as? YubikitFlutterError {
                sendResult(FlutterError(code: ykError.code, message: ykError.message, details: ykError.details))
            } else {
                sendResult(FlutterError(code: "yubikit.error", message: "\(error!.localizedDescription)", details: nil))
            }
        }
    
        switch call.method {
            case "sendCommands":
                let commands: NSArray = call.argument(0)
                let application: FlutterStandardTypedData = call.argument(1)
                let verify = (call.arguments as! [Any?])[2] as? FlutterStandardTypedData
                logger.debug("Received select application command: \(application.data.hexDescription)")
                yubiKeyConnection.connection { connection, error in
                    guard let connection = connection else {
                        handleError(error: error!)
                        return
                    }
                    guard let smartCardInterface = connection.smartCardInterface else {
                        self.logger.error("Smart card interface not present!")
                        sendResult(FlutterError(code: "yubikit.error", message: "Smart card not present", details: nil))
                        return
                    }
                    Task {
                        do {
                            try await smartCardInterface.selectApp(application: application.data)
                            let result = try await smartCardInterface.runCommands(commands: commands, verify: verify?.data)
                            sendResult(result)
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
