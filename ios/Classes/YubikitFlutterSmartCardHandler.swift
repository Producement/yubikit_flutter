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
        
        func runCommand(smartCardInterface: YKFSmartCardInterface, data: Data) {
            smartCardInterface.executeCommand(YKFAPDU(data: data)!, completion: { data, error in
                guard let data = data else {
                    self.logger.error("Failed to execute smart card command: \(error!.localizedDescription)")
                    result(FlutterError(code: "smart.card.error", message: "\(error!.localizedDescription)", details: ""))
                    return
                }
                self.logger.info("Smart card command executed")
                result(data)
            })
        }
        
        switch(call.method) {
            case "smartCardCommand":
            let apdu: FlutterStandardTypedData = argument(0)
            let application: FlutterStandardTypedData = argument(1)
            self.logger.debug("Received command: \(apdu.data.hexadecimalString)")
            yubiKeyConnection.connection { connection in
                guard let smartCardInterface = connection.smartCardInterface else {
                    self.logger.error("Smart card interface not present!")
                    result(FlutterError(code: "smart.card.error", message: "Smart card not present", details: ""))
                    return
                }
                if(application.elementCount > 0) {
                    guard let applicationApdu = YKFSelectApplicationAPDU(cla: 0x00, ins: 0xA4, p1: 0x04, p2: 0x00, data: application.data, type: .short) else {
                        self.logger.error("Failed to construct application APDU")
                        result(FlutterError(code: "smart.card.error", message: "Application APDU invalid", details: ""))
                        return
                    }
                    smartCardInterface.selectApplication(applicationApdu) { data, error in
                        if error != nil {
                            self.logger.error("Failed to execute smart card select application command: \(error!.localizedDescription)")
                            result(FlutterError(code: "smart.card.error", message: "\(error!.localizedDescription)", details: ""))
                            return
                        }
                        runCommand(smartCardInterface: smartCardInterface, data: apdu.data)
                    }
                } else {
                    runCommand(smartCardInterface: smartCardInterface, data: apdu.data)
                }
            }
            default:
                return false
        }
        return true
    }
}

private extension Data {
    var hexadecimalString: String {
        let charA: UInt8 = 0x61
        let char0: UInt8 = 0x30
        func byteToChar(_ b: UInt8) -> Character {
            Character(UnicodeScalar(b > 9 ? charA + b - 10 : char0 + b))
        }
        let hexChars = flatMap {[
            byteToChar(($0 >> 4) & 0xF),
            byteToChar($0 & 0xF)
        ]}
        return String(hexChars)
    }
}
