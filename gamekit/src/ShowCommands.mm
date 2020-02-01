// Apple GameKit Defold Extension
// ShowCommands.mm

#include <stdio.h>
#include <dmsdk/sdk.h>
#include "LuaEvents.h"
// #include "LuaStackDump.h"

#import <GameKit/GameKit.h>
#import "ShowCommands.h"

@interface ShowCommands ()

@property (nonatomic, readwrite) GameCenterDelegate *gameCenterDelegatePtr;

@end

@implementation ShowCommands

- (instancetype)initWithGameCenterDelegate:(GameCenterDelegate *)delegate
{
    self = [super init];
    if (self) {
        self.gameCenterDelegatePtr = delegate;
    }
    return self;
}

- (void)gcShowCommandFromLuaState:(lua_State *)L
{
    // printLuaStack(L);
    if(lua_gettop(L) == 2) {
        luaL_checktype(L, 2, LUA_TTABLE);
        luaL_checktype(L, 1, LUA_TSTRING);
        const char *command = lua_tostring( L, 1 );
        // NSLog(@"DEBUG:NSLog [ShowCommands.mm] gcShowCommandFromLuaState called command = %s", command);
///////////// command = leaderboardsUI
        if(strcmp(command, "leaderboardsUI") == 0) {
            NSString *leaderboardID = [self.gameCenterDelegatePtr getLeaderboardIDFromLuaState:L];
            
            GKLeaderboardTimeScope timeScope = [self.gameCenterDelegatePtr getLeaderboardTimeScopeFromLuaState:L];
            lua_settop(L, 0); // clear the whole stack
            GKGameCenterViewController *gameCenterViewController = [[GKGameCenterViewController alloc] init];
            if (gameCenterViewController != nil) {
                // NSLog(@"DEBUG:NSLog [ShowCommands.mm] gameCenterViewController NOT nil");
                gameCenterViewController.gameCenterDelegate = self.gameCenterDelegatePtr;
                gameCenterViewController.viewState = GKGameCenterViewControllerStateLeaderboards;
                gameCenterViewController.leaderboardTimeScope = timeScope;
                gameCenterViewController.leaderboardIdentifier = leaderboardID;
                [self.gameCenterDelegatePtr presentGameCenterViewController:gameCenterViewController];
            }
///////////// command = achievementsUI
        } else if(strcmp(command, "achievementsUI") == 0) {
            lua_settop(L, 0); // clear the whole stack
            GKGameCenterViewController *gameCenterViewController = [[GKGameCenterViewController alloc] init];
            if (gameCenterViewController != nil) {
                // NSLog(@"DEBUG:NSLog [ShowCommands.mm] gameCenterViewController NOT nil");
                gameCenterViewController.gameCenterDelegate = self.gameCenterDelegatePtr;
                gameCenterViewController.viewState = GKGameCenterViewControllerStateAchievements;
                [self.gameCenterDelegatePtr presentGameCenterViewController:gameCenterViewController];
            }
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