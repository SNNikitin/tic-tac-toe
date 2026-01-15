#import "NativeGame.h"
#if __has_include(<TicTacToeNative/TicTacToeNative-Swift.h>)
#import <TicTacToeNative/TicTacToeNative-Swift.h>
#else
#import "TicTacToeNative-Swift.h"
#endif

@implementation NativeGame {
    GameBridge *_game;
}

- (instancetype)init {
    if (self = [super init]) {
        _game = [[GameBridge alloc] init];
    }
    return self;
}

- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:(const facebook::react::ObjCTurboModule::InitParams &)params {
    return std::make_shared<facebook::react::NativeGameSpecJSI>(params);
}

+ (NSString *)moduleName {
    return @"NativeGame";
}

- (void)newGame:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
    [_game newGameWithResolve:resolve reject:reject];
}

- (void)setDifficulty:(NSString *)difficulty resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
    [_game setDifficulty:difficulty resolve:resolve reject:reject];
}

- (void)playTurn:(double)row col:(double)col resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
    [_game playTurnWithRow:row col:col resolve:resolve reject:reject];
}

@end
