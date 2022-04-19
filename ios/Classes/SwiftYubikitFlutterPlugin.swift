import Flutter
import UIKit
import Foundation
import OSLog

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
        case "getPlatformVersion":
            result("iOS " + UIDevice.current.systemVersion)
        case "connect":
            logger.info("Setting up Yubikey connection")
            if(connection != nil) {
                logger.info("Connection already made!")
                result("Connection already made!")
                return
            }
            connection = YubiKeyConnection();
            result(nil)
        case "disconnect":
            logger.info("Disconnecting")
            connection = nil
            result(nil)
        case "verifyPin":
            logger.info("Verifying PIN")
            guard let connection = connection else {
                result("Connection not active!")
                return
            }
            connection.connection { connection in
                self.logger.info("Connection set up: \(connection.debugDescription!)")
                connection.pivSession { session, error in
                    self.logger.info("PIV session set up: \(session.debugDescription)")
                    guard let session = session else {
                        result("Error! Reason: " + (error?.localizedDescription)!)
                        return
                    }
                    let pin  = call.arguments as! String
                    session.verifyPin(pin) { code, error in
                        self.logger.info("PIN verification result: \(code.description)")
                        result(nil)
                    }
                }
            }
        default:
            result("No such method: " + call.method)
        }
    }
}
