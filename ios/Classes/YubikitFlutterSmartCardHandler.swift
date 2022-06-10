//
//  YubikitFlutterSmartCardHandler.swift
//  yubikit_flutter
//
//  Created by Maido Kaara on 06.05.2022.
//

import Foundation
import OSLog
import YubiKit

public class YubikitFlutterSmartCardHandler {
    let logger = Logger()
    let yubiKeyConnection: YubiKeyConnection
    
    init(yubiKeyConnection: YubiKeyConnection) {
        self.yubiKeyConnection = yubiKeyConnection
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) -> Bool {
        
        func argument<T>(_ index: Int) -> T {
            return (call.arguments as! Array<Any>)[index] as! T
        }
        
        func sendResult(_ res: Any) {
            yubiKeyConnection.stop()
            result(res)
        }
        
        func runCommand(smartCardInterface: YKFSmartCardInterface, data: Data, verify: Data?) {
            if(!(verify?.isEmpty ?? true)) {
                smartCardInterface.executeCommand(YKFAPDU(data: verify!)!, completion: { verifyData, error in
                    guard verifyData != nil else {
                        handleError(error: error)
                        return
                    }
                    smartCardInterface.executeCommand(YKFAPDU(data: data)!, completion: { data, error in
                        guard let data = data else {
                            handleError(error: error)
                            return
                        }
                        self.logger.info("Returning result")
                        sendResult(data)
                        self.logger.info("Done!")
                    })
                });
            } else {
                smartCardInterface.executeCommand(YKFAPDU(data: data)!, completion: { data, error in
                    guard let data = data else {
                        handleError(error: error)
                        return
                    }
                    self.logger.info("Returning result")
                    sendResult(data)
                    self.logger.info("Done!")

                })
            }
        }
        
        func handleError(error: Error?) {
            logger.error("Error! Reason: \(error!.localizedDescription)")
            if let scError = error as? YKFSessionError {
                sendResult(FlutterError(code: "yubikit.smartcard.error", message: "\(scError.localizedDescription)", details: scError.code))
            } else {
                sendResult(FlutterError(code: "yubikit.error", message: "\(error!.localizedDescription)", details: nil))
            }
        }
    
        
        switch(call.method) {
            case "sendCommand":
                let apdu: FlutterStandardTypedData = argument(0)
                let application: FlutterStandardTypedData = argument(1)
                let verify = (call.arguments as! Array<Any?>)[2] as? FlutterStandardTypedData
                self.logger.debug("Received select application command: \(application.data.hexDescription)")
                yubiKeyConnection.connection { connection in
                    guard let smartCardInterface = connection.smartCardInterface else {
                        self.logger.error("Smart card interface not present!")
                        sendResult(FlutterError(code: "yubikit.error", message: "Smart card not present", details: nil))
                        return
                    }
                    guard let applicationApdu = YKFSelectApplicationAPDU(cla: 0x00, ins: 0xA4, p1: 0x04, p2: 0x00, data: application.data, type: .short) else {
                        self.logger.error("Failed to construct application APDU")
                        sendResult(FlutterError(code: "yubikit.error", message: "Application APDU invalid", details: nil))
                        return
                    }
                    smartCardInterface.selectApplication(applicationApdu) { data, error in
                        if error != nil {
                            self.logger.error("Failed to select application, trying to activate: \(error!.localizedDescription)")
                            guard let activateApdu = YKFAPDU(cla: 0x00, ins: 0x44, p1: 0x00, p2: 0x00, data:Data(), type: .short) else {
                                self.logger.error("Failed to construct activate APDU")
                                sendResult(FlutterError(code: "yubikit.error", message: "Activate APDU invalid", details: ""))
                                return
                            }
                            smartCardInterface.executeCommand(activateApdu, completion: { data, error in
                                if error != nil {
                                    handleError(error: error)
                                    return
                                }
                                self.logger.info("Smart card activation executed")
                                smartCardInterface.selectApplication(applicationApdu) { data, error in
                                    if error != nil {
                                        handleError(error: error)
                                        return
                                    }
                                    self.logger.debug("Received command: \(apdu.data.hexDescription)")
                                    runCommand(smartCardInterface: smartCardInterface, data: apdu.data, verify: verify?.data)
                                }
                            })
                        } else {
                            self.logger.debug("Received command: \(apdu.data.hexDescription)")
                            runCommand(smartCardInterface: smartCardInterface, data: apdu.data, verify: verify?.data)
                        }
                        
                    }
                }
            default:
                return false
        }
        return true
    }
}

private extension Data {
    var hexDescription: String {
        return reduce("") {$0 + String(format: "%02x", $1)}
    }
    
    var bytes: [UInt8] {
        var byteArray = [UInt8](repeating: 0, count: self.count)
        self.copyBytes(to: &byteArray, count: self.count)
        return byteArray
    }
}
