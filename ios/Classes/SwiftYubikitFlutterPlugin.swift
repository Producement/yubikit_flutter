import Flutter
import UIKit
import Foundation
import OSLog
import YubiKit

public class SwiftYubikitFlutterPlugin: NSObject, FlutterPlugin {
    let logger = Logger()
    let yubiKeyConnection:YubiKeyConnection
    let pivHandler: YubikitFlutterPivHandler
    let smartCardHandler: YubikitFlutterSmartCardHandler
    
    public override init() {
        yubiKeyConnection = YubiKeyConnection()
        pivHandler = YubikitFlutterPivHandler(yubiKeyConnection: yubiKeyConnection)
        smartCardHandler = YubikitFlutterSmartCardHandler(yubiKeyConnection: yubiKeyConnection)
        super.init()
    }
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let pivChannel = FlutterMethodChannel(name: "yubikit_flutter_piv", binaryMessenger: registrar.messenger())
        let instance = SwiftYubikitFlutterPlugin()
        let smartCardChannel = FlutterMethodChannel(name: "yubikit_flutter_sc", binaryMessenger: registrar.messenger())
        
        let eventChannel = FlutterEventChannel(name: "yubikit_flutter_status", binaryMessenger: registrar.messenger())
        eventChannel.setStreamHandler(instance.yubiKeyConnection)
        
        registrar.addMethodCallDelegate(instance, channel: pivChannel)
        registrar.addMethodCallDelegate(instance, channel: smartCardChannel)
    }

    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        if(pivHandler.handle(call, result: result)) {
            logger.info("PIV handled")
            return
        } else if(smartCardHandler.handle(call, result: result)) {
            logger.info("Smart Card handled")
            return
        } else {
            switch(call.method) {
                case "start":
                    yubiKeyConnection.start()
                    result(nil)
                case "stop":
                    yubiKeyConnection.stop()
                    result(nil)
                default:
                    result(FlutterMethodNotImplemented)
            }
        }
    }

}
