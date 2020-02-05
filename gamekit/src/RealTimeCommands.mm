// Apple GameKit Defold Extension
// RealTimeCommands.mm

#include <stdio.h>
#include <dmsdk/sdk.h>
#include "LuaEvents.h"
#include "LuaStackDump.h"

#import <GameKit/GameKit.h>
#import "RealTimeCommands.h"

@interface RealTimeCommands ()

@property (nonatomic, readwrite) GameCenterDelegate *gameCenterDelegatePtr;

@end

@implementation RealTimeCommands

- (instancetype)initWithGameCenterDelegate:(GameCenterDelegate *)delegate
{
    self = [super init];
    if (self) {
        self.gameCenterDelegatePtr = delegate;
    }
    return self;
}

- (void)gcRealTimeCommandFromLuaState:(lua_State *)L
{
    printLuaStack(L);
    if(lua_gettop(L) == 2) {
        luaL_checktype(L, 2, LUA_TTABLE);
        luaL_checktype(L, 1, LUA_TSTRING);
        const char *command = lua_tostring( L, 1 );
        NSLog(@"DEBUG:NSLog [RealTimeCommands.mm] gcRealTimeCommandFromLuaState called command = %s", command);
///////////// command = registerMatchmakerCallback
        if(strcmp(command, "registerMatchmakerCallback") == 0) {
            // NSString *leaderboardID = [self.gameCenterDelegatePtr getLeaderboardIDFromLuaState:L];
            
            // GKLeaderboardTimeScope timeScope = [self.gameCenterDelegatePtr getLeaderboardTimeScopeFromLuaState:L];
            // lua_settop(L, 0); // clear the whole stack
            // GKGameCenterViewController *gameCenterViewController = [[GKGameCenterViewController alloc] init];
            // if (gameCenterViewController != nil) {
            //     // NSLog(@"DEBUG:NSLog [ShowCommands.mm] gameCenterViewController NOT nil");
            //     gameCenterViewController.gameCenterDelegate = self.gameCenterDelegatePtr;
            //     gameCenterViewController.viewState = GKGameCenterViewControllerStateLeaderboards;
            //     gameCenterViewController.leaderboardTimeScope = timeScope;
            //     gameCenterViewController.leaderboardIdentifier = leaderboardID;
            //     [self.gameCenterDelegatePtr presentGameCenterViewController:gameCenterViewController];
            // }
///////////// command = temp
        } else if(strcmp(command, "temp") == 0) {
            // next show command

        } else {
            dmLogError("gc_show() string command expected but got %s", command);
        }
    } else {
        dmLogError("gc_show() requires a string command and parameters table only");
    }
}

@end