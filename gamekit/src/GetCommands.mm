// Apple GameKit Defold Extension
// GetCommands.mm

#include <stdio.h>
#include <dmsdk/sdk.h>
#include "LuaEvents.h"
#include "LuaStackDump.h"

#import <GameKit/GameKit.h>
#import "GetCommands.h"

@interface GetCommands ()

@property (nonatomic, readwrite) GameCenterDelegate *gameCenterDelegatePtr;

@end

@implementation GetCommands

- (instancetype)initWithGameCenterDelegate:(GameCenterDelegate *)delegate
{
    self = [super init];
    if (self) {
        self.gameCenterDelegatePtr = delegate;
    }
    return self;
}

- (void)gcGetCommandFromLuaState:(lua_State *)L
{
    // printLuaStack(L);
    if(lua_gettop(L) == 2) {
        luaL_checktype(L, 2, LUA_TTABLE);
        luaL_checktype(L, 1, LUA_TSTRING);
        const char *command = lua_tostring( L, 1 );
        NSLog(@"DEBUG:NSLog [GetCommands.mm] gcGetCommandFromLuaState called command = %s", command);
///////////// command = scores
        if(strcmp(command, "scores") == 0) {
            int luaCallbackRef = getTemporaryGameCenterCallbackLuaRef(L);
            int luaSelfRef = getTemporaryGameCenterSelfLuaRef(L);

            NSString *leaderboardID = [self.gameCenterDelegatePtr getLeaderboardIDFromLuaState:L];

            GKLeaderboardPlayerScope playerScope = GKLeaderboardPlayerScopeGlobal;
            lua_getfield( L, -1, "playerScope" );
            if(lua_type(L, -1) != LUA_TNIL) {
                luaL_checktype(L, -1, LUA_TSTRING);
                const char *scope = lua_tostring(L, -1);
                if (strcmp(scope, "Global") == 0) {
                    playerScope = GKLeaderboardPlayerScopeGlobal;
                } else if (strcmp(scope, "FriendsOnly") == 0 ) {
                    playerScope = GKLeaderboardPlayerScopeFriendsOnly;
                } else {
                    dmLogError("gc_get() parameter string 'Global' or 'FriendsOnly' expected but got %s", scope);
                }
                lua_pop(L, 1);
            } else {
                dmLogError("gc_get() parameters table key 'playerScope' expected");
            }

            GKLeaderboardTimeScope timeScope = [self.gameCenterDelegatePtr getLeaderboardTimeScopeFromLuaState:L];
            
            NSUInteger rangeMin = 0;
            NSUInteger rangeMax = 0;
            lua_getfield( L, -1, "range" );
            if(lua_type(L, -1) != LUA_TNIL) {
                luaL_checktype(L, 2, LUA_TTABLE);
                int length = (int) lua_objlen(L, -1);  // get length of table array
                if (length != 2) {
                    dmLogError("gc_get() parameter table array with 2 elements expected but got %i", length);
                } else {
                    lua_rawgeti(L, -1, 1);  // array at -1, pushes value of table array[1] onto top of stack
                    rangeMin = lua_tointeger(L, -1);
                    lua_pop(L, 1);
                    
                    lua_rawgeti(L, -1, 2);  // array at -1, pushes value of table array[2] onto top of stack
                    rangeMax = lua_tointeger(L, -1);
                    lua_pop(L, 1);
                }
            } else {
                dmLogError("gc_get() parameters table key 'range' expected");
            }
            lua_settop(L, 0); // clear the whole stack
            // printLuaStack(L);

            GKLeaderboard *leaderboardRequest = [[GKLeaderboard alloc] init];
            if (leaderboardRequest != nil) {
                NSLog(@"DEBUG:NSLog [GetCommands.mm] loadScores leaderboardRequest = %@", leaderboardRequest);
                leaderboardRequest.identifier = leaderboardID;
                leaderboardRequest.playerScope = playerScope;
                leaderboardRequest.timeScope = timeScope;
                leaderboardRequest.range = NSMakeRange(rangeMin, rangeMax);
                [leaderboardRequest loadScoresWithCompletionHandler:^(NSArray *scores, NSError *error) {
                    NSLog(@"DEBUG:NSLog [GetCommands.mm] loadScores error = %@", error);
                    NSLog(@"DEBUG:NSLog [GetCommands.mm] loadScores scores = %@", scores);
                    if(error) {
                        const char *description = [[self.gameCenterDelegatePtr stringAppendErrorDescription:[error localizedDescription]
                            errorCode:[error code]] UTF8String];
                        sendGameCenterCallbackLuaErrorEvent(L, luaCallbackRef, luaSelfRef, [error code], description);
                    } else if(error == nil && [scores count] == 0) {
                        const char *description = [[self.gameCenterDelegatePtr stringAppendErrorDescription:@"No scores for reqested leaderboardID" 
                            errorCode:GKErrorInvalidParameter] UTF8String];
                        sendGameCenterCallbackLuaErrorEvent(L, luaCallbackRef, luaSelfRef, GKErrorInvalidParameter, description);
                    } else {
                        NSInteger scoresCount = [scores count];
                        lua_newtable(L); // create lua table for event
                        // push items and set feilds
                        lua_pushstring(L, "scoresList");
			            lua_setfield(L, -2, "type");
                        lua_pushinteger(L, scoresCount);
                        lua_setfield(L, -2, "scoresCount");
			            lua_pushstring(L, [[leaderboardRequest title] UTF8String]);
                        lua_setfield(L, -2, "leaderboardTitle");
                        if([leaderboardRequest groupIdentifier] != nil) {
                            lua_pushstring(L, [[leaderboardRequest groupIdentifier] UTF8String]);
                        } else {
                            lua_pushnil(L);
                        }
                        lua_setfield(L, -2, "leaderboardGroupID");
                        lua_pushinteger(L, [leaderboardRequest maxRange]);
                        lua_setfield(L, -2, "leaderboardMaxRange");
                        if([leaderboardRequest localPlayerScore] != nil) {
                            [self.gameCenterDelegatePtr newLuaTableFromScoreObject:[leaderboardRequest localPlayerScore] luaState:L];
                        } else {
                            lua_pushnil(L);
                        }
                        lua_setfield(L, -2, "localPlayerScore"); // add localPlayerScore table or localPlayerScore nil to event table
                        lua_newtable(L); // create lua table for scores
                        
                        int i = 1;
                        for(GKScore *score in scores) {
                            lua_pushinteger(L, i);
                            [self.gameCenterDelegatePtr newLuaTableFromScoreObject:score luaState:L];
                            lua_settable(L, -3);
                            i++;
                        }
                        lua_setfield(L, -2, "scores"); // add scores table to event table
                        // store reference to lua event table
			            int luaTableRef = dmScript::Ref(L, LUA_REGISTRYINDEX);
                        // printLuaStack(L);
                        sendGameCenterCallbackLuaEvent(L, luaCallbackRef, luaSelfRef, luaTableRef);
                    }
                }];
            } else {
                const char *description = [[self.gameCenterDelegatePtr stringAppendErrorDescription:@"Score request not valid" 
                errorCode:GKErrorInvalidParameter] UTF8String];
                sendGameCenterCallbackLuaErrorEvent(L, luaCallbackRef, luaSelfRef, GKErrorInvalidParameter, description);
            }
            [leaderboardRequest release];
///////////// command = leaderboards           
        } else if(strcmp(command, "leaderboards") == 0) {
            int luaCallbackRef = getTemporaryGameCenterCallbackLuaRef(L);
            int luaSelfRef = getTemporaryGameCenterSelfLuaRef(L);
            lua_settop(L, 0); // clear the whole stack

            [GKLeaderboard loadLeaderboardsWithCompletionHandler:^(NSArray *leaderboards, NSError *error) {
                NSLog(@"DEBUG:NSLog [GetCommands.mm] loadLeaderboards error = %@", error);
                NSLog(@"DEBUG:NSLog [GetCommands.mm] loadLeaderboards leaderboards = %@", leaderboards);
                if(error) {
                    const char *description = [[self.gameCenterDelegatePtr stringAppendErrorDescription:[error localizedDescription]
                        errorCode:[error code]] UTF8String];
                    sendGameCenterCallbackLuaErrorEvent(L, luaCallbackRef, luaSelfRef, [error code], description);
                } else if(error == nil && [leaderboards count] == 0) {
	                const char *description = [[self.gameCenterDelegatePtr stringAppendErrorDescription:@"Game Center Leaderboards are non existent" 
	                    errorCode:GKErrorInvalidParameter] UTF8String];
	                sendGameCenterCallbackLuaErrorEvent(L, luaCallbackRef, luaSelfRef, GKErrorInvalidParameter, description);
                } else {
                    NSInteger leaderboardsCount = [leaderboards count];
                    lua_newtable(L); // create lua table for event
                    // push items and set feilds
                    lua_pushstring(L, "leaderboardsList");
                    lua_setfield(L, -2, "type");
                    lua_pushinteger(L, leaderboardsCount);
                    lua_setfield(L, -2, "leaderboardsCount");
                    lua_newtable(L); // create lua table for leaderboards
                    
                    int i = 1;
                    for(GKLeaderboard *leaderboard in leaderboards) {
                        lua_pushinteger(L, i);
                        [self.gameCenterDelegatePtr newLuaTableFromLeaderboardObject:leaderboard luaState:L];
                        lua_settable(L, -3);
                        i++;
                    }
                    lua_setfield(L, -2, "leaderboards"); // add leaderboards table to event table
                    // store reference to lua event table
                    int luaTableRef = dmScript::Ref(L, LUA_REGISTRYINDEX);
                    // printLuaStack(L);
                    sendGameCenterCallbackLuaEvent(L, luaCallbackRef, luaSelfRef, luaTableRef);
                }
            }];
///////////// command = defaultLeaderboardID           
        } else if(strcmp(command, "defaultLeaderboardID") == 0) {
            int luaCallbackRef = getTemporaryGameCenterCallbackLuaRef(L);
            int luaSelfRef = getTemporaryGameCenterSelfLuaRef(L);
            lua_settop(L, 0); // clear the whole stack
            
            [[GKLocalPlayer localPlayer] loadDefaultLeaderboardIdentifierWithCompletionHandler:
             ^(NSString *leaderboardIdentifier, NSError *error) {
                NSLog(@"DEBUG:NSLog [GetCommands.mm] loadDefaultLeaderboardID error = %@", error);
                if(error) {
                    const char *description = [[self.gameCenterDelegatePtr stringAppendErrorDescription:[error localizedDescription]
                        errorCode:[error code]] UTF8String];
                    sendGameCenterCallbackLuaErrorEvent(L, luaCallbackRef, luaSelfRef, [error code], description);
                } else if(error == nil && leaderboardIdentifier == nil) {
                    const char *description = [[self.gameCenterDelegatePtr stringAppendErrorDescription:@"Game Center Default LeaderboardID is non existent" 
                        errorCode:GKErrorInvalidParameter] UTF8String];
                    sendGameCenterCallbackLuaErrorEvent(L, luaCallbackRef, luaSelfRef, GKErrorInvalidParameter, description);
                } else {
                    lua_newtable(L); // create lua table for event
                    // push items and set feilds
                    lua_pushstring( L, "defaultLeaderboardID" );
                    lua_setfield( L, -2, "type" );
                    lua_pushstring( L, [leaderboardIdentifier UTF8String]);
                    lua_setfield( L, -2, "leaderboardID" );
                    // store reference to lua event table
                    int luaTableRef = dmScript::Ref(L, LUA_REGISTRYINDEX);
                    // printLuaStack(L);
                    sendGameCenterCallbackLuaEvent(L, luaCallbackRef, luaSelfRef, luaTableRef);
                 }
             }];
///////////// command = leaderboardImage           
        } else if(strcmp(command, "leaderboardImage") == 0) {
            int luaCallbackRef = getTemporaryGameCenterCallbackLuaRef(L);
            int luaSelfRef = getTemporaryGameCenterSelfLuaRef(L);

            NSString *leaderboardID = [self.gameCenterDelegatePtr getLeaderboardIDFromLuaState:L];
            lua_settop(L, 0); // clear the whole stack
            
            [GKLeaderboard loadLeaderboardsWithCompletionHandler:^(NSArray *leaderboards, NSError *error) {
                NSLog(@"DEBUG:NSLog [GetCommands.mm] loadLeaderboards error = %@", error);
                NSLog(@"DEBUG:NSLog [GetCommands.mm] loadLeaderboards leaderboards = %@", leaderboards);
                if(error) {
                    const char *description = [[self.gameCenterDelegatePtr stringAppendErrorDescription:[error localizedDescription]
                        errorCode:[error code]] UTF8String];
                    sendGameCenterCallbackLuaErrorEvent(L, luaCallbackRef, luaSelfRef, [error code], description);
                } else if(error == nil && [leaderboards count] == 0) {
                    const char *description = [[self.gameCenterDelegatePtr stringAppendErrorDescription:@"Game Center Leaderboards are non existent" 
	                    errorCode:GKErrorInvalidParameter] UTF8String];
	                sendGameCenterCallbackLuaErrorEvent(L, luaCallbackRef, luaSelfRef, GKErrorInvalidParameter, description);
                } else {
                    GKLeaderboard *selectedLeaderboard = nil;
                    for(GKLeaderboard *leaderboard in leaderboards) {
                        if([[leaderboard identifier] isEqualToString:leaderboardID]) {
                            selectedLeaderboard = leaderboard;
                            break;
                        }
                    }
                    NSLog(@"DEBUG:NSLog [GetCommands.mm] selectedLeaderboard = %@", selectedLeaderboard);
                    if(selectedLeaderboard != nil) {
                        [self.gameCenterDelegatePtr sendImageFromLeaderboard:selectedLeaderboard luaCallbackRef:luaCallbackRef luaSelfRef:luaSelfRef luaState:L];
                    } else {
                        const char *description = [[self.gameCenterDelegatePtr stringAppendErrorDescription:@"Game Center LeaderboardID not found" 
                            errorCode:GKErrorInvalidParameter] UTF8String];
                        sendGameCenterCallbackLuaErrorEvent(L, luaCallbackRef, luaSelfRef, GKErrorInvalidParameter, description);
                    }
                }
            }];
///////////// command = leaderboardSets           
        } else if(strcmp(command, "leaderboardSets") == 0) {
            int luaCallbackRef = getTemporaryGameCenterCallbackLuaRef(L);
            int luaSelfRef = getTemporaryGameCenterSelfLuaRef(L);
            lua_settop(L, 0); // clear the whole stack

            [GKLeaderboardSet loadLeaderboardSetsWithCompletionHandler:^(NSArray *leaderboardSets, NSError *error) {
                NSLog(@"DEBUG:NSLog [GetCommands.mm] loadLeaderboardSets error = %@", error);
                NSLog(@"DEBUG:NSLog [GetCommands.mm] loadLeaderboardSets leaderboardSets = %@", leaderboardSets);
                if(error) {
                    const char *description = [[self.gameCenterDelegatePtr stringAppendErrorDescription:[error localizedDescription]
                        errorCode:[error code]] UTF8String];
                    sendGameCenterCallbackLuaErrorEvent(L, luaCallbackRef, luaSelfRef, [error code], description);
                } else if(error == nil && [leaderboardSets count] == 0) {
                    const char *description = [[self.gameCenterDelegatePtr stringAppendErrorDescription:@"Game Center Leaderboard Sets are non existent" 
                        errorCode:GKErrorInvalidParameter] UTF8String];
                    sendGameCenterCallbackLuaErrorEvent(L, luaCallbackRef, luaSelfRef, GKErrorInvalidParameter, description);
                } else {
                    NSInteger leaderboardSetsCount = [leaderboardSets count];
                    lua_newtable(L); // create lua table for event
                    // push items and set feilds
                    lua_pushstring(L, "leaderboardSetsList");
                    lua_setfield(L, -2, "type");
                    lua_pushinteger(L, leaderboardSetsCount);
                    lua_setfield(L, -2, "leaderboardSetsCount");
                    lua_newtable(L); // create lua table for leaderboardSets

                    int i = 1;
                    for(GKLeaderboardSet *leaderboardSet in leaderboardSets) {
                        lua_pushinteger(L, i);
                        [self.gameCenterDelegatePtr newLuaTableFromLeaderboardSetObject:leaderboardSet luaState:L];
                        lua_settable(L, -3);
                        i++;
                    }
                    lua_setfield(L, -2, "leaderboardSets"); // add leaderboardSets table to event table
                    // store reference to lua event table
                    int luaTableRef = dmScript::Ref(L, LUA_REGISTRYINDEX);
                    // printLuaStack(L);
                    sendGameCenterCallbackLuaEvent(L, luaCallbackRef, luaSelfRef, luaTableRef);
                }
            }];
///////////// command = leaderboardsInLeaderboardSet          
        } else if(strcmp(command, "leaderboardsInLeaderboardSet") == 0) {
            int luaCallbackRef = getTemporaryGameCenterCallbackLuaRef(L);
            int luaSelfRef = getTemporaryGameCenterSelfLuaRef(L);

            NSString *leaderboardSetID = nil;
            lua_getfield(L, -1, "leaderboardSetID");
            if(lua_type(L, -1) != LUA_TNIL) {
                luaL_checktype(L, -1, LUA_TSTRING);
                leaderboardSetID = [NSString stringWithUTF8String:lua_tostring(L, -1)];
                lua_pop(L, 1);
            } else {
                dmLogError("parameters table key 'leaderboardSetID' expected");
            }
            NSLog(@"DEBUG:NSLog [GetCommands.mm] leaderboardSetImage leaderboardSetID = %@", leaderboardSetID);
            lua_settop(L, 0); // clear the whole stack
            
            [GKLeaderboardSet loadLeaderboardSetsWithCompletionHandler:^(NSArray *leaderboardSets, NSError *error) {
                NSLog(@"DEBUG:NSLog [GetCommands.mm] loadLeaderboardSets error = %@", error);
                NSLog(@"DEBUG:NSLog [GetCommands.mm] loadLeaderboardSets leaderboardSets = %@", leaderboardSets);
                if(error) {
                    const char *description = [[self.gameCenterDelegatePtr stringAppendErrorDescription:[error localizedDescription]
                        errorCode:[error code]] UTF8String];
                    sendGameCenterCallbackLuaErrorEvent(L, luaCallbackRef, luaSelfRef, [error code], description);
                } else if(error == nil && [leaderboardSets count] == 0) {
                    const char *description = [[self.gameCenterDelegatePtr stringAppendErrorDescription:@"Game Center Leaderboard Sets are non existent" 
                        errorCode:GKErrorInvalidParameter] UTF8String];
                    sendGameCenterCallbackLuaErrorEvent(L, luaCallbackRef, luaSelfRef, GKErrorInvalidParameter, description);
                } else {
                    GKLeaderboardSet *selectedLeaderboardSet = nil;
                    for(GKLeaderboardSet *leaderboardSet in leaderboardSets) {
                        if([[leaderboardSet identifier] isEqualToString:leaderboardSetID]) {
                            selectedLeaderboardSet = leaderboardSet;
                            break;
                        }
                    }
                    NSLog(@"DEBUG:NSLog [GetCommands.mm] selectedLeaderboardSet = %@", selectedLeaderboardSet);
                    if(selectedLeaderboardSet != nil) {
                        [selectedLeaderboardSet loadLeaderboardsWithCompletionHandler:^(NSArray *leaderboards, NSError *error) {
                            NSLog(@"DEBUG:NSLog [GetCommands.mm] loadLeaderboards error = %@", error);
                            NSLog(@"DEBUG:NSLog [GetCommands.mm] loadLeaderboards leaderboards = %@", leaderboards);
                            if(error) {
                                const char *description = [[self.gameCenterDelegatePtr stringAppendErrorDescription:[error localizedDescription]
                                    errorCode:[error code]] UTF8String];
                                sendGameCenterCallbackLuaErrorEvent(L, luaCallbackRef, luaSelfRef, [error code], description);
                            } else if(error == nil && [leaderboards count] == 0) {
                                const char *description = [[self.gameCenterDelegatePtr stringAppendErrorDescription:@"Game Center Leaderboards are non existent" 
                                    errorCode:GKErrorInvalidParameter] UTF8String];
                                sendGameCenterCallbackLuaErrorEvent(L, luaCallbackRef, luaSelfRef, GKErrorInvalidParameter, description);
                            } else {
                                NSInteger leaderboardsCount = [leaderboards count];
                                lua_newtable(L); // create lua table for event
                                // push items and set feilds
                                lua_pushstring(L, "leaderboardsList");
                                lua_setfield(L, -2, "type");
                                lua_pushinteger(L, leaderboardsCount);
                                lua_setfield(L, -2, "leaderboardsCount");
                                lua_newtable(L); // create lua table for leaderboards
                                
                                int i = 1;
                                for(GKLeaderboard *leaderboard in leaderboards) {
                                    lua_pushinteger(L, i);
                                    [self.gameCenterDelegatePtr newLuaTableFromLeaderboardObject:leaderboard luaState:L];
                                    lua_settable(L, -3);
                                    i++;
                                }
                                lua_setfield(L, -2, "leaderboards"); // add leaderboards table to event table
                                // store reference to lua event table
                                int luaTableRef = dmScript::Ref(L, LUA_REGISTRYINDEX);
                                // printLuaStack(L);
                                sendGameCenterCallbackLuaEvent(L, luaCallbackRef, luaSelfRef, luaTableRef);
                            }
                        }];
                    } else {
                        const char *description = [[self.gameCenterDelegatePtr stringAppendErrorDescription:@"Game Center LeaderboardSetID not found" 
                            errorCode:GKErrorInvalidParameter] UTF8String];
                        sendGameCenterCallbackLuaErrorEvent(L, luaCallbackRef, luaSelfRef, GKErrorInvalidParameter, description);
                    }
                }
            }];
///////////// command = leaderboardSetImage          
        } else if(strcmp(command, "leaderboardSetImage") == 0) {
            int luaCallbackRef = getTemporaryGameCenterCallbackLuaRef(L);
            int luaSelfRef = getTemporaryGameCenterSelfLuaRef(L);

            NSString *leaderboardSetID = nil;
            lua_getfield(L, -1, "leaderboardSetID");
            if(lua_type(L, -1) != LUA_TNIL) {
                luaL_checktype(L, -1, LUA_TSTRING);
                leaderboardSetID = [NSString stringWithUTF8String:lua_tostring(L, -1)];
                lua_pop(L, 1);
            } else {
                dmLogError("parameters table key 'leaderboardSetID' expected");
            }
            NSLog(@"DEBUG:NSLog [GetCommands.mm] leaderboardSetImage leaderboardSetID = %@", leaderboardSetID);
            lua_settop(L, 0); // clear the whole stack
            
            [GKLeaderboardSet loadLeaderboardSetsWithCompletionHandler:^(NSArray *leaderboardSets, NSError *error) {
                NSLog(@"DEBUG:NSLog [GetCommands.mm] loadLeaderboardSets error = %@", error);
                NSLog(@"DEBUG:NSLog [GetCommands.mm] loadLeaderboardSets leaderboardSets = %@", leaderboardSets);
                if(error) {
                    const char *description = [[self.gameCenterDelegatePtr stringAppendErrorDescription:[error localizedDescription]
                        errorCode:[error code]] UTF8String];
                    sendGameCenterCallbackLuaErrorEvent(L, luaCallbackRef, luaSelfRef, [error code], description);
                } else if(error == nil && [leaderboardSets count] == 0) {
                    const char *description = [[self.gameCenterDelegatePtr stringAppendErrorDescription:@"Game Center Leaderboard Sets are non existent" 
                        errorCode:GKErrorInvalidParameter] UTF8String];
                    sendGameCenterCallbackLuaErrorEvent(L, luaCallbackRef, luaSelfRef, GKErrorInvalidParameter, description);
                } else {
                    GKLeaderboardSet *selectedLeaderboardSet = nil;
                    for(GKLeaderboardSet *leaderboardSet in leaderboardSets) {
                        if([[leaderboardSet identifier] isEqualToString:leaderboardSetID]) {
                            selectedLeaderboardSet = leaderboardSet;
                            break;
                        }
                    }
                    NSLog(@"DEBUG:NSLog [GetCommands.mm] selectedLeaderboardSet = %@", selectedLeaderboardSet);
                    if(selectedLeaderboardSet != nil) {
                        [self.gameCenterDelegatePtr sendImageFromLeaderboardSet:selectedLeaderboardSet luaCallbackRef:luaCallbackRef luaSelfRef:luaSelfRef luaState:L];
                    } else {
                        const char *description = [[self.gameCenterDelegatePtr stringAppendErrorDescription:@"Game Center LeaderboardSetID not found" 
                            errorCode:GKErrorInvalidParameter] UTF8String];
                        sendGameCenterCallbackLuaErrorEvent(L, luaCallbackRef, luaSelfRef, GKErrorInvalidParameter, description);
                    }
                }
            }];
///////////// command = achievementsProgress           
        } else if(strcmp(command, "achievementsProgress") == 0) {
            int luaCallbackRef = getTemporaryGameCenterCallbackLuaRef(L);
            int luaSelfRef = getTemporaryGameCenterSelfLuaRef(L);
            lua_settop(L, 0); // clear the whole stack

            [GKAchievement loadAchievementsWithCompletionHandler:^(NSArray *achievements, NSError *error) {
                 NSLog(@"DEBUG:NSLog [GetCommands.mm] loadAchievements error = %@", error);
                 NSLog(@"DEBUG:NSLog [GetCommands.mm] loadAchievements achievements = %@", achievements);
                if(error) {
                    const char *description = [[self.gameCenterDelegatePtr stringAppendErrorDescription:[error localizedDescription]
                        errorCode:[error code]] UTF8String];
                    sendGameCenterCallbackLuaErrorEvent(L, luaCallbackRef, luaSelfRef, [error code], description);
                } else if(error == nil && [achievements count] == 0) {
                    const char *description = [[self.gameCenterDelegatePtr stringAppendErrorDescription:@"Game Center Achievements progress is non existent"
		                errorCode:GKErrorInvalidParameter] UTF8String];
	                sendGameCenterCallbackLuaErrorEvent(L, luaCallbackRef, luaSelfRef, GKErrorInvalidParameter, description);
                } else {
                    NSInteger achievementsCount = [achievements count];
                    lua_newtable(L); // create lua table for event
                    // push items and set feilds
                    lua_pushstring(L, "achievementsList");
                    lua_setfield(L, -2, "type");
                    lua_pushinteger(L, achievementsCount);
                    lua_setfield(L, -2, "achievementsCount");
                    lua_newtable(L); // create lua table for achievements
                    
                    int i = 1;
                    for(GKAchievement *achievement in achievements) {
                        lua_pushinteger(L, i);
                        [self.gameCenterDelegatePtr newLuaTableFromAchievementObject:achievement luaState:L];
                        lua_settable(L, -3);
                        i++;
                    }
                    lua_setfield(L, -2, "achievements"); // add achievements table to event table
                    // store reference to lua event table
                    int luaTableRef = dmScript::Ref(L, LUA_REGISTRYINDEX);
                    // printLuaStack(L);
                    sendGameCenterCallbackLuaEvent(L, luaCallbackRef, luaSelfRef, luaTableRef);
                }
            }];
///////////// command = achievementsDescription           
        } else if(strcmp(command, "achievementsDescription") == 0) {
            int luaCallbackRef = getTemporaryGameCenterCallbackLuaRef(L);
            int luaSelfRef = getTemporaryGameCenterSelfLuaRef(L);
            lua_settop(L, 0); // clear the whole stack

            [GKAchievementDescription loadAchievementDescriptionsWithCompletionHandler:^(NSArray *descriptions, NSError *error) {
                NSLog(@"DEBUG:NSLog [GetCommands.mm] loadAchievementDescriptions error = %@", error);
                NSLog(@"DEBUG:NSLog [GetCommands.mm] loadAchievementDescriptions descriptions = %@", descriptions);
                if(error) {
                    const char *description = [[self.gameCenterDelegatePtr stringAppendErrorDescription:[error localizedDescription]
                        errorCode:[error code]] UTF8String];
                    sendGameCenterCallbackLuaErrorEvent(L, luaCallbackRef, luaSelfRef, [error code], description);
                } else if(error == nil && [descriptions count] == 0) {
                    const char *description = [[self.gameCenterDelegatePtr stringAppendErrorDescription:@"Game Center Achievements descriptions are non existent" 
		                errorCode:GKErrorInvalidParameter] UTF8String];
	                sendGameCenterCallbackLuaErrorEvent(L, luaCallbackRef, luaSelfRef, GKErrorInvalidParameter, description);
                } else {
                    NSInteger descriptionsCount = [descriptions count];
                    lua_newtable(L); // create lua table for event
                    // push items and set feilds
                    lua_pushstring(L, "achievementsDescList");
                    lua_setfield(L, -2, "type");
                    lua_pushinteger(L, descriptionsCount);
                    lua_setfield(L, -2, "descriptionsCount");
                    lua_newtable(L); // create lua table for descriptions
                    
                    int i = 1;
                    for(GKAchievementDescription *description in descriptions) {
                        lua_pushinteger(L, i);
                        [self.gameCenterDelegatePtr newLuaTableFromAchievementDescriptionObject:description luaState:L];
                        lua_settable(L, -3);
                        i++;
                    }
                    lua_setfield(L, -2, "descriptions"); // add descriptions table to event table
                    // store reference to lua event table
                    int luaTableRef = dmScript::Ref(L, LUA_REGISTRYINDEX);
                    // printLuaStack(L);
                    sendGameCenterCallbackLuaEvent(L, luaCallbackRef, luaSelfRef, luaTableRef);
                }
            }];
///////////// command = achievementImage           
        } else if(strcmp(command, "achievementImage") == 0) {
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
            lua_settop(L, 0); // clear the whole stack
            
            [GKAchievementDescription loadAchievementDescriptionsWithCompletionHandler:^(NSArray *descriptions, NSError *error) {
                NSLog(@"DEBUG:NSLog [GetCommands.mm] loadAchievementDescriptions error = %@", error);
                NSLog(@"DEBUG:NSLog [GetCommands.mm] loadAchievementDescriptions descriptions = %@", descriptions);
                if(error) {
                    const char *description = [[self.gameCenterDelegatePtr stringAppendErrorDescription:[error localizedDescription]
                        errorCode:[error code]] UTF8String];
                    sendGameCenterCallbackLuaErrorEvent(L, luaCallbackRef, luaSelfRef, [error code], description);
                } else if(error == nil && [descriptions count] == 0) {
                    const char *description = [[self.gameCenterDelegatePtr stringAppendErrorDescription:@"Game Center Achievements descriptions are non existent" 
                        errorCode:GKErrorInvalidParameter] UTF8String];
                    sendGameCenterCallbackLuaErrorEvent(L, luaCallbackRef, luaSelfRef, GKErrorInvalidParameter, description);
                } else {
                    GKAchievementDescription *selectedAchievementDescription = nil;
                    for(GKAchievementDescription *description in descriptions) {
                        if([[description identifier] isEqualToString:achievementID]) {
                            selectedAchievementDescription = description;
                            break;
                        }
                    }
                    NSLog(@"DEBUG:NSLog [GetCommands.mm] selectedAchievementDescription = %@", selectedAchievementDescription);
                    if(selectedAchievementDescription != nil) {
                        [self.gameCenterDelegatePtr sendImageFromAchievementDescription:selectedAchievementDescription luaCallbackRef:luaCallbackRef luaSelfRef:luaSelfRef luaState:L];
                    } else {
                        const char *description = [[self.gameCenterDelegatePtr stringAppendErrorDescription:@"Game Center achievementID not found" 
                            errorCode:GKErrorInvalidParameter] UTF8String];
                        sendGameCenterCallbackLuaErrorEvent(L, luaCallbackRef, luaSelfRef, GKErrorInvalidParameter, description);
                    }
                }
            }];
///////////// command = temp           
        } else if(strcmp(command, "temp") == 0) {
            // add next get command
        } else {
            dmLogError("gc_get() string command expected but got %s", command);
        }
    } else {
        dmLogError("gc_get() requires a string command and parameters table only");
    }
}

@end