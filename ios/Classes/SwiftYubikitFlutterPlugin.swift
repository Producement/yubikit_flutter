import Flutter
import Foundation
import OSLog
import UIKit
import YubiKit

public class SwiftYubikitFlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        YubikitFlutterPivHandler.register(with: registrar)
        YubikitFlutterSmartCardHandler.register(with: registrar)
        YubikitFlutterOpenPGPHandler.register(with: registrar)
    }
}
