#import "YubikitFlutterPlugin.h"
#if __has_include(<yubikit_flutter/yubikit_flutter-Swift.h>)
#import <yubikit_flutter/yubikit_flutter-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "yubikit_flutter-Swift.h"
#endif

@implementation YubikitFlutterPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftYubikitFlutterPlugin registerWithRegistrar:registrar];
}
@end
