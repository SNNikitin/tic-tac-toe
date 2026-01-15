#import "NativeNetwork.h"
#if __has_include(<TicTacToeNative/TicTacToeNative-Swift.h>)
#import <TicTacToeNative/TicTacToeNative-Swift.h>
#else
#import "TicTacToeNative-Swift.h"
#endif

@implementation NativeNetwork {
    NetworkBridge *_network;
}

- (instancetype)init {
    if (self = [super init]) {
        _network = [[NetworkBridge alloc] init];
    }
    return self;
}

- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:(const facebook::react::ObjCTurboModule::InitParams &)params {
    return std::make_shared<facebook::react::NativeNetworkSpecJSI>(params);
}

+ (NSString *)moduleName {
    return @"NativeNetwork";
}

- (void)configure:(NSString *)url resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
    [_network configureWithUrl:url resolve:resolve reject:reject];
}

- (void)send:(NSString *)email playerName:(NSString *)playerName won:(BOOL)won difficulty:(NSString *)difficulty duration:(double)duration playedAt:(NSString *)playedAt streak:(double)streak resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
    [_network sendWithEmail:email playerName:playerName won:won difficulty:difficulty duration:duration playedAt:playedAt streak:streak resolve:resolve reject:reject];
}

@end
