// Apple GameKit Defold Extension
// SendCommands.mm

#include <stdio.h>
#include <dmsdk/sdk.h>
#include "LuaEvents.h"
#include "LuaStackDump.h"

#import <GameKit/GameKit.h>
#import "SendCommands.h"

@interface SendCommands ()

@property (nonatomic, readwrite) GameCenterDelegate *gameCenterDelegatePtr;

@end

@implementation SendCommands

- (instancetype)initWithGameCenterDelegate:(GameCenterDelegate *)delegate
{
    self = [super init];
    if (self) {
        self.gameCenterDelegatePtr = delegate;
    }
    return self;
}

- (void)gcSendCommandFromLuaState:(lua_State *)L
{
    printLuaStack(L);
    if(lua_gettop(L) == 2) {
        luaL_checktype(L, 2, LUA_TTABLE);
        luaL_checktype(L, 1, LUA_TSTRING);
        const char *command = lua_tostring( L, 1 );
        NSLog(@"DEBUG:NSLog [SendCommands.mm] gcSendCommandFromLuaState called command = %s", command);
///////////// command = score   
        if(strcmp(command, "score") == 0) {
            int luaCallbackRef = getTemporaryGameCenterCallbackLuaRef(L);
            int luaSelfRef = getTemporaryGameCenterSelfLuaRef(L);
            
            NSString *leaderboardID = [self.gameCenterDelegatePtr getLeaderboardIDFromLuaState:L];

            int64_t score = 0;
            lua_getfield(L, -1, "value");
            if(lua_type(L, -1) != LUA_TNIL) {
                luaL_checktype(L, -1, LUA_TNUMBER);
                score = (int64_t) lua_tonumber(L, -1);
                lua_pop(L, 1);
            } else {
                dmLogError("gc_send() parameters table key 'value' expected");
            }

            uint64_t context = 0;
            lua_getfield(L, -1, "context");
            if(lua_type(L, -1) == LUA_TNUMBER) {
                context = (uint64_t) lua_tonumber(L, -1); 
            }
            // context is an optional parameter, so no error if no context parameter sent
            lua_settop(L, 0); // clear the whole stack
            // printLuaStack(L);

            GKScore *scoreReporter = [[GKScore alloc] initWithLeaderboardIdentifier:leaderboardID];
            scoreReporter.value = score;
            scoreReporter.context = context;
            NSArray *scores = @[scoreReporter];
            [GKScore reportScores:scores withCompletionHandler:^(NSError *error) {
                NSLog(@"DEBUG:NSLog [SendCommands.mm] reportScores error = %@", error);
                const char *description = nil;
                if(error) {
                    description = [[self.gameCenterDelegatePtr stringAppendErrorDescription:[error localizedDescription] 
                    errorCode:[error code]] UTF8String];
                    sendGameCenterCallbackLuaErrorEvent(L, luaCallbackRef, luaSelfRef, [error code], description);
                } else {
                    description = "Score has been sent to game center leaderboard";
                    sendGameCenterCallbackLuaSuccessEvent(L, luaCallbackRef, luaSelfRef, description);
                }
            }];
            [scoreReporter release];
//////////// command = setDefaultLeaderboardID 
        } else if(strcmp(command, "setDefaultLeaderboardID") == 0) {
            int luaCallbackRef = getTemporaryGameCenterCallbackLuaRef(L);
            int luaSelfRef = getTemporaryGameCenterSelfLuaRef(L);
            
            NSString *leaderboardID = [self.gameCenterDelegatePtr getLeaderboardIDFromLuaState:L];
            lua_settop(L, 0); // clear the whole stack

            [[GKLocalPlayer localPlayer] setDefaultLeaderboardIdentifier:leaderboardID completionHandler:^(NSError *error) {
                NSLog(@"DEBUG:NSLog [SendCommands.mm] setDefaultLeaderboardID error = %@", error);
                const char *description = nil;
                if(error) {
                    description = [[self.gameCenterDelegatePtr stringAppendErrorDescription:[error localizedDescription] 
                    errorCode:[error code]] UTF8String];
                    sendGameCenterCallbackLuaErrorEvent(L, luaCallbackRef, luaSelfRef, [error code], description);
                } else {
                    description = "Game Center default leaderboardID has been set";
                    sendGameCenterCallbackLuaSuccessEvent(L, luaCallbackRef, luaSelfRef, description);
                }
            }];
///////////// command = achievementProgress 
        } else if(strcmp(command, "achievementProgress") == 0) {
            int luaCallbackRef = getTemporaryGameCenterCallbackLuaRef(L);
            int luaSelfRef = getTemporaryGameCenterSelfLuaRef(L);

            NSString *achievementID = nil;
            lua_getfield(L, -1, "achievementID");
            if(lua_type(L, -1) != LUA_TNIL) {
                luaL_checktype(L, -1, LUA_TSTRING);
                achievementID = [NSString stringWithUTF8String:lua_tostring(L, -1)];
                lua_pop(L, 1);
            } else {
                dmLogError("parameters table key 'achievementID' expected");
            }

            double percent = 0.0;
            lua_getfield(L, -1, "percentComplete");
            if(lua_type(L, -1) != LUA_TNIL) {
                luaL_checktype(L, -1, LUA_TNUMBER);
                percent = (double) lua_tonumber(L, -1);
                lua_pop(L, 1);
            } else {
                dmLogError("gc_send() parameters table key 'percentComplete' expected");
            }

            BOOL bannerEnabled = NO;
            lua_getfield(L, -1, "showsCompletionBanner");
            if(lua_type(L, -1) != LUA_TNIL) {
                luaL_checktype(L, -1, LUA_TBOOLEAN);
                bannerEnabled = (BOOL) lua_toboolean(L, -1);
                lua_pop(L, 1);
            } else {
                dmLogError("gc_send() parameters table key 'showsCompletionBanner' expected");
            }
            lua_settop(L, 0); // clear the whole stack
            
            GKAchievement *achievementReporter = [[GKAchievement alloc] initWithIdentifier:achievementID];
            achievementReporter.percentComplete = percent;
            achievementReporter.showsCompletionBanner = bannerEnabled;
            NSLog(@"DEBUG:NSLog [SendCommands.mm] achievementReporter = %@", achievementReporter);
            NSArray *achievements = @[achievementReporter];
            [GKAchievement reportAchievements:achievements withCompletionHandler:^(NSError *error) {
                NSLog(@"DEBUG:NSLog [SendCommands.mm] reportAchievements error = %@", error);
                const char *description = nil;
                if(error) {
                    description = [[self.gameCenterDelegatePtr stringAppendErrorDescription:[error localizedDescription] 
                    errorCode:[error code]] UTF8String];
                    sendGameCenterCallbackLuaErrorEvent(L, luaCallbackRef, luaSelfRef, [error code], description);
                } else {
                    description = "Achievement progress has been sent to game center achievement";
                    sendGameCenterCallbackLuaSuccessEvent(L, luaCallbackRef, luaSelfRef, description);
                }
            }];
            [achievementReporter release];
///////////// command = resetAchievements 
        } else if(strcmp(command, "resetAchievements") == 0) {
            int luaCallbackRef = getTemporaryGameCenterCallbackLuaRef(L);
            int luaSelfRef = getTemporaryGameCenterSelfLuaRef(L);
            lua_settop(L, 0); // clear the whole stack

            [GKAchievement resetAchievementsWithCompletionHandler:^(NSError *error) {
                NSLog(@"DEBUG:NSLog [SendCommands.mm] resetAchievements error = %@", error);
                const char *description = nil;
                if(error) {
                    description = [[self.gameCenterDelegatePtr stringAppendErrorDescription:[error localizedDescription] 
                    errorCode:[error code]] UTF8String];
                    sendGameCenterCallbackLuaErrorEvent(L, luaCallbackRef, luaSelfRef, [error code], description);
                } else {
                    description = "Achievements have been reset on game center";
                    sendGameCenterCallbackLuaSuccessEvent(L, luaCallbackRef, luaSelfRef, description);
                }
            }];
///////////// command = saveGame 
        } else if(strcmp(command, "saveGame") == 0) {
            int luaCallbackRef = getTemporaryGameCenterCallbackLuaRef(L);
            int luaSelfRef = getTemporaryGameCenterSelfLuaRef(L);

            NSData *gameData = nil;
            NSString *dataUTF8String = nil;
            lua_getfield(L, -1, "gameData");
            if(lua_type(L, -1) != LUA_TNIL) {
                luaL_checktype(L, -1, LUA_TSTRING);
                dataUTF8String = [NSString stringWithUTF8String:lua_tostring( L, -1 )];
                gameData = [dataUTF8String dataUsingEncoding:NSUTF8StringEncoding];
                lua_pop(L, 1);
            } else {
                dmLogError("parameters table key 'gameData' expected");
            }
            NSLog(@"DEBUG:NSLog [SendCommands.mm] gameData = %s", [dataUTF8String UTF8String]);

            NSString *dataName = nil;
            lua_getfield(L, -1, "withName");
            if(lua_type(L, -1) != LUA_TNIL) {
                luaL_checktype(L, -1, LUA_TSTRING);
                dataName = [NSString stringWithUTF8String:lua_tostring(L, -1)];
                lua_pop(L, 1);
            } else {
                dmLogError("parameters table key 'withName' expected");
            }
            NSLog(@"DEBUG:NSLog [SendCommands.mm] withName = %@", dataName);
            lua_settop(L, 0); // clear the whole stack

            [[GKLocalPlayer localPlayer] saveGameData:gameData withName:dataName completionHandler:^(GKSavedGame *savedGame, NSError *error) {
                NSLog(@"DEBUG:NSLog [SendCommands.mm] saveGameData error = %@", error);
                NSLog(@"DEBUG:NSLog [SendCommands.mm] saveGameData savedGame = %@", savedGame);
                const char *description = nil;
                if(error) {
                    // continual error 27: not logged into iCloud even though all accounts are logged into iCloud and GameCenter
                    description =  [[self.gameCenterDelegatePtr stringAppendErrorDescription:[error localizedDescription] 
                    errorCode:[error code]] UTF8String];
                    sendGameCenterCallbackLuaErrorEvent(L, luaCallbackRef, luaSelfRef, [error code], description);
                } else {
                    NSLog(@"DEBUG:NSLog [SendCommands.mm] saveGameData success!");
                    // when saveGameData works return the following information from GKSavedGame savedGame object
                    // deviceName, modificationDate, name
                    // https://developer.apple.com/documentation/gamekit/gksavedgame?language=objc
                    // temporary success callback event below for testing only until error 27 is resolved
                    description = "Game Data has been saved to iCloud Drive";
                    sendGameCenterCallbackLuaSuccessEvent(L, luaCallbackRef, luaSelfRef, description);
                }
            }];
///////////// command = temp 
        } else if(strcmp(command, "temp") == 0) {
            // next send command

        } else {
            dmLogError("gc_send() string command expected but got %s", command);
        }
    } else {
        dmLogError("gc_send() requires a string command and parameters table only");
    }
}

@end