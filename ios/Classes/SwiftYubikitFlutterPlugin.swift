import Flutter

public class SwiftYubikitFlutterPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        YubikitFlutterPivHandler.register(with: registrar)
        YubikitFlutterSmartCardHandler.register(with: registrar)
        YubikitFlutterOpenPGPHandler.register(with: registrar)
    }
}
