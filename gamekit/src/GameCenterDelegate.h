// Apple GameKit Defold Extension
// GameCenterDelegate.h

//#import <UIKit/UIKit.h>
//@compatibility_alias UIImage NSImage; //error need import for UIImage

#if defined(DM_PLATFORM_OSX) 
//@compatibility_alias ExistingClass OldClass; // code for iOS but make UI classes compatible with OSX NS
@compatibility_alias UIViewController NSViewController;
#endif

//@interface GameCenterDelegate : NSObject <GKGameCenterControllerDelegate, GKLocalPlayerListener, GKMatchDelegate, GKMatchmakerViewControllerDelegate, GKTurnBasedMatchmakerViewControllerDelegate>
// add to @interface other delegates above as they are needed
@interface GameCenterDelegate : NSObject <GKGameCenterControllerDelegate>
// delegate properties
@property (nonatomic, assign) BOOL isGameCenterEnabled; // game center features are enabled after a localPlayer has been authenticated.
@property (nonatomic, assign) BOOL isLocalPlayerListenerRegistered;
@property (nonatomic, assign) BOOL isRTMatchmakerCallbackEnabled;
@property (nonatomic, assign) UIViewController *authenticateViewController;

// delegate methods
- (void)presentGameCenterViewController:(GKGameCenterViewController *)gameCenterViewController;
- (NSString *)stringAppendErrorDescription:(NSString *)errorDescription errorCode:(NSInteger)errorCode;
- (NSInteger)newLuaTableFromScoreObject:(GKScore *)score luaState:(lua_State *)L;
- (NSInteger)newLuaTableFromLeaderboardObject:(GKLeaderboard *)leaderboard luaState:(lua_State *)L;
- (NSInteger)newLuaTableFromLeaderboardSetObject:(GKLeaderboardSet *)leaderboardSet luaState:(lua_State *)L;
- (NSInteger)newLuaTableFromAchievementObject:(GKAchievement *)achievement luaState:(lua_State *)L;
- (NSInteger)newLuaTableFromAchievementDescriptionObject:(GKAchievementDescription *)achvDescription luaState:(lua_State *)L;
- (NSString *)getLeaderboardIDFromLuaState:(lua_State *)L;
- (GKLeaderboardTimeScope)getLeaderboardTimeScopeFromLuaState:(lua_State *)L;
- (NSInteger)newLuaTableFromBitmap:(unsigned char *)bitmap width:(size_t)width height:(size_t)height luaState:(lua_State *)L;
- (void)sendImageFromLeaderboard:(GKLeaderboard *)leaderboard luaCallbackRef:(NSInteger)cbRef luaSelfRef:(NSInteger)selfRef luaState:(lua_State *)L;
- (void)sendImageFromLeaderboardSet:(GKLeaderboardSet *)leaderboardSet luaCallbackRef:(NSInteger)cbRef luaSelfRef:(NSInteger)selfRef luaState:(lua_State *)L;
- (void)sendImageFromAchievementDescription:(GKAchievementDescription *)achvDescription luaCallbackRef:(NSInteger)cbRef luaSelfRef:(NSInteger)selfRef luaState:(lua_State *)L;

@end