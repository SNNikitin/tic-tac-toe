#import "NativeDatabase.h"
#if __has_include(<TicTacToeNative/TicTacToeNative-Swift.h>)
#import <TicTacToeNative/TicTacToeNative-Swift.h>
#else
#import "TicTacToeNative-Swift.h"
#endif

@implementation NativeDatabase {
    DatabaseBridge *_database;
}

- (instancetype)init {
    if (self = [super init]) {
        _database = [[DatabaseBridge alloc] init];
    }
    return self;
}

- (std::shared_ptr<facebook::react::TurboModule>)getTurboModule:(const facebook::react::ObjCTurboModule::InitParams &)params {
    return std::make_shared<facebook::react::NativeDatabaseSpecJSI>(params);
}

+ (NSString *)moduleName {
    return @"NativeDatabase";
}

- (void)getPlayerId:(NSString *)name resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
    [_database getPlayerIdWithName:name resolve:resolve reject:reject];
}

- (void)saveGame:(double)playerId won:(BOOL)won difficulty:(NSString *)difficulty duration:(double)duration playedAt:(NSString *)playedAt resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
    [_database saveGameWithPlayerId:playerId won:won difficulty:difficulty duration:duration playedAt:playedAt resolve:resolve reject:reject];
}

- (void)getCurrentStreak:(double)playerId resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
    [_database getCurrentStreakWithPlayerId:playerId resolve:resolve reject:reject];
}

- (void)getBestStreak:(double)playerId resolve:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
    [_database getBestStreakWithPlayerId:playerId resolve:resolve reject:reject];
}

- (void)getLeaderboard:(RCTPromiseResolveBlock)resolve reject:(RCTPromiseRejectBlock)reject {
    [_database getLeaderboardWithResolve:resolve reject:reject];
}

@end
