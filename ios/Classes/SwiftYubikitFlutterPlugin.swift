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
    let yubiKeyConnection = YubiKeyConnection()
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let pivHandler = YubikitFlutterPivHandler(yubiKeyConnection: yubiKeyConnection)
        let smartCardHandler = YubikitFlutterSmartCardHandler(yubiKeyConnection: yubiKeyConnection)
        if(pivHandler.handle(call, result: result)) {
            return
        } else if(smartCardHandler.handle(call, result: result)) {
            return
        } else {
            result(FlutterMethodNotImplemented)
        }
    }

}
