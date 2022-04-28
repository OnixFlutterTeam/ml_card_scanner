#import "MlCardScannerPlugin.h"
#if __has_include(<ml_card_scanner/ml_card_scanner-Swift.h>)
#import <ml_card_scanner/ml_card_scanner-Swift.h>
#else
// Support project import fallback if the generated compatibility header
// is not copied when this plugin is created as a library.
// https://forums.swift.org/t/swift-static-libraries-dont-copy-generated-objective-c-header/19816
#import "ml_card_scanner-Swift.h"
#endif

@implementation MlCardScannerPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftMlCardScannerPlugin registerWithRegistrar:registrar];
}
@end
