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
///////////// command = sendDataToAllPlayers
        if(strcmp(command, "sendDataToAllPlayers") == 0) {
            if(self.gameCenterDelegatePtr.isRTMatchCallbackRegistered == YES) {
                if((self.gameCenterDelegatePtr.isMatchStarted == YES) && (self.gameCenterDelegatePtr.currentMatch != nil)) {
                    NSData *data = nil;
                    lua_getfield( L, -1, "data" );
                    if(lua_type(L, -1) != LUA_TNIL) {
                        luaL_checktype(L, -1, LUA_TSTRING);
                        const char *dataUTF8String = lua_tostring(L, -1);
                        data = [NSData dataWithBytes:dataUTF8String length:strlen(dataUTF8String)]; // needs further testing
                        // if above corrupts the data use code below instead
                        // NSString *dataUTF8String = [NSString stringWithUTF8String:lua_tostring( L, -1 )];
                        // data = [dataUTF8String dataUsingEncoding:NSUTF8StringEncoding];
                        lua_pop(L, 1);
                    } else {
                        dmLogError("parameters table key 'data' expected");
                    }

                    GKMatchSendDataMode dataMode = GKMatchSendDataReliable;
                    lua_getfield( L, -1, "dataMode" );
                    if(lua_type(L, -1) != LUA_TNIL) {
                        luaL_checktype(L, -1, LUA_TSTRING);
                        const char *mode = lua_tostring(L, -1);
                        if(strcmp (mode, "Reliable") == 0) {
                            dataMode = GKMatchSendDataReliable;
                        } else if(strcmp (mode, "Unreliable") == 0 ) {
                            dataMode = GKMatchSendDataUnreliable;
                        } else {
                            dmLogError("'Reliable' or 'Unreliable' string expected but got %s", mode);
                        }
                        lua_pop(L, 1);
                    } else {
                        dmLogError("parameters table key 'dataMode' expected");
                    }
                    
                    BOOL isConfirmed = NO;
                    lua_getfield( L, -1, "isConfirmed" );
                    if(lua_type(L, -1) != LUA_TNIL) {
                        luaL_checktype(L, -1, LUA_TBOOLEAN);
                        isConfirmed = (BOOL) lua_toboolean(L, -1);
                    } else {
                        dmLogError("parameters table key 'isConfirmed' expected");
                    }
                    lua_settop(L, 0); // clear the whole stack

                    NSError *error = nil;
                    const char *description = nil;
                    BOOL isSuccess = [self.gameCenterDelegatePtr.currentMatch sendDataToAllPlayers:data withDataMode:dataMode error:&error];
                    if((isSuccess == YES) && (isConfirmed == YES)) {
                        description = "data was successfully queued to all players";
                        sendGameCenterRegisteredCallbackLuaSuccessEvent(L, GC_RT_MATCH_CALLBACK, GC_RT_MATCH_LUA_INSTANCE, description);
                    } else if(error != nil) {
                        description = [[self.gameCenterDelegatePtr stringAppendErrorDescription:[error localizedDescription] 
                            errorCode:[error code]] UTF8String];
                        sendGameCenterRegisteredCallbackLuaErrorEvent(L, GC_RT_MATCH_CALLBACK, GC_RT_MATCH_LUA_INSTANCE, [error code], description);
                    }
                } else {
                    lua_settop(L, 0); // clear the whole stack
                    dmLogError("You must receive a 'matchStarted' event before you call gc_realtime( 'sendDataToAllPlayers' )");
                }
            } else {
                lua_settop(L, 0); // clear the whole stack
                dmLogError("You must call gc_realtime( 'registerMatchCallback' ) before you call gc_realtime( 'sendDataToAllPlayers' )");
            }
///////////// command = sendDataToPlayers
        } else if(strcmp(command, "sendDataToPlayers") == 0) {
            if(self.gameCenterDelegatePtr.isRTMatchCallbackRegistered == YES) {
                if((self.gameCenterDelegatePtr.isMatchStarted == YES) && (self.gameCenterDelegatePtr.currentMatch != nil)) {
                    NSData *data = nil;
                    lua_getfield( L, -1, "data" );
                    if(lua_type(L, -1) != LUA_TNIL) {
                        luaL_checktype(L, -1, LUA_TSTRING);
                        const char *dataUTF8String = lua_tostring(L, -1);
                        data = [NSData dataWithBytes:dataUTF8String length:strlen(dataUTF8String)]; // needs further testing
                        // if above corrupts the data use code below instead
                        // NSString *dataUTF8String = [NSString stringWithUTF8String:lua_tostring( L, -1 )];
                        // data = [dataUTF8String dataUsingEncoding:NSUTF8StringEncoding];
                        lua_pop(L, 1);
                    } else {
                        dmLogError("parameters table key 'data' expected");
                    }

                    NSMutableArray *playerIDs = [[NSMutableArray alloc] init];
                    lua_getfield(L, -1, "playerIDs");
                    if(lua_type(L, -1) != LUA_TNIL) {
                        luaL_checktype(L, -1, LUA_TTABLE);
                        int playersIDsLength = (int) lua_objlen(L, -1);
                        for(int i=1; i<=playersIDsLength; i++) {
                            lua_rawgeti(L, -1, i);
                            if(lua_type( L, -1 ) == LUA_TSTRING) {
                                [playerIDs addObject:[NSString stringWithUTF8String:lua_tostring(L, -1)]];
                            } else {
                                dmLogError("playerID string expected but got %s", luaL_typename(L, -1));
                            }
                            lua_pop(L, 1);
                        }
                        lua_pop(L, 1);
                    } else {
                        dmLogError("parameters table key 'playerIDs' expected");
                    }
                    
                    GKMatchSendDataMode dataMode = GKMatchSendDataReliable;
                    lua_getfield(L, -1, "dataMode");
                    if(lua_type(L, -1) != LUA_TNIL) {
                        luaL_checktype(L, -1, LUA_TSTRING);
                        const char *mode = lua_tostring(L, -1);
                        if(strcmp (mode, "Reliable") == 0) {
                            dataMode = GKMatchSendDataReliable;
                        } else if(strcmp (mode, "Unreliable") == 0 ) {
                            dataMode = GKMatchSendDataUnreliable;
                        } else {
                            dmLogError("'Reliable' or 'Unreliable' string expected but got %s", mode);
                        }
                        lua_pop(L, 1);
                    } else {
                        dmLogError("parameters table key 'dataMode' expected");
                    }
                    
                    BOOL isConfirmed = NO;
                    lua_getfield(L, -1, "isConfirmed");
                    if(lua_type(L, -1) != LUA_TNIL) {
                        luaL_checktype(L, -1, LUA_TBOOLEAN);
                        isConfirmed = (BOOL) lua_toboolean(L, -1);
                    } else {
                        dmLogError("parameters table key 'isConfirmed' expected");
                    }
                    lua_settop(L, 0); // clear the whole stack

                    [GKPlayer loadPlayersForIdentifiers:playerIDs withCompletionHandler:^(NSArray *players, NSError *loadError) {
                        if(loadError) {
                            const char *description = [[self.gameCenterDelegatePtr stringAppendErrorDescription:[loadError localizedDescription] 
                                errorCode:[loadError code]] UTF8String];
                            sendGameCenterRegisteredCallbackLuaErrorEvent(L, GC_RT_MATCH_CALLBACK, GC_RT_MATCH_LUA_INSTANCE, [loadError code], description);
                        } else {
                            NSError *error = nil;
                            const char *description = nil;
                            BOOL isSuccess = [self.gameCenterDelegatePtr.currentMatch sendData:data toPlayers:players dataMode:dataMode error:&error];
                            if((isSuccess == YES) && (isConfirmed == YES)) {
                                description = "data was successfully queued to players";
                                sendGameCenterRegisteredCallbackLuaSuccessEvent(L, GC_RT_MATCH_CALLBACK, GC_RT_MATCH_LUA_INSTANCE, description);
                            } else if(error != nil) {
                                description = [[self.gameCenterDelegatePtr stringAppendErrorDescription:[error localizedDescription] 
                                    errorCode:[error code]] UTF8String];
                                sendGameCenterRegisteredCallbackLuaErrorEvent(L, GC_RT_MATCH_CALLBACK, GC_RT_MATCH_LUA_INSTANCE, [error code], description);
                            }
                        }
                    }];
                    [playerIDs release];
                } else {
                    lua_settop(L, 0); // clear the whole stack
                    dmLogError("You must receive a 'matchStarted' event before you call gc_realtime( 'sendDataToPlayers' )");
                }
            } else {
                lua_settop(L, 0); // clear the whole stack
                dmLogError("You must call gc_realtime( 'registerMatchCallback' ) before you call gc_realtime( 'sendDataToPlayers' )");
            }
///////////// command = registerMatchmakerCallback
        } else if(strcmp(command, "registerMatchmakerCallback") == 0) {
            if(self.gameCenterDelegatePtr.isRTMatchmakerCallbackRegistered == NO) {
                lua_getfield(L, -1, "callback");
                if(lua_type(L, -1) != LUA_TNIL) {
                    if(registerGameCenterCallbackLuaRef(L, GC_RT_MATCHMAKER_CALLBACK, GC_RT_MATCHMAKER_LUA_INSTANCE)) {
                        lua_settop(L, 0); // clear the whole stack
                        const char *description = "realtime matchmaker callback is registered";
                        sendGameCenterRegisteredCallbackLuaSuccessEvent(L, GC_RT_MATCHMAKER_CALLBACK, GC_RT_MATCHMAKER_LUA_INSTANCE, description);
                        // register listener for localPlayer only once for Invite Real-Time matchmaking Events,
                        // Challenge Events and Turn-Based Events
                        if (self.gameCenterDelegatePtr.isLocalPlayerListenerRegistered == NO) {
                            [[GKLocalPlayer localPlayer] registerListener:self.gameCenterDelegatePtr];
                            self.gameCenterDelegatePtr.isLocalPlayerListenerRegistered = YES;
                        }
                        self.gameCenterDelegatePtr.isRTMatchmakerCallbackRegistered = YES;
                    } else {
                        dmLogError("failed to register realtime matchmaker callback");
                    }
                } else {
                    dmLogError("parameters table key 'callback' expected");
                }
            } else {
                lua_settop(L, 0); // clear the whole stack
                const char *description = [[self.gameCenterDelegatePtr stringAppendErrorDescription:@"realtime matchmaker callback is already registered"
                    errorCode:GKErrorAPINotAvailable] UTF8String];
			    sendGameCenterRegisteredCallbackLuaErrorEvent(L, GC_RT_MATCHMAKER_CALLBACK, GC_RT_MATCHMAKER_LUA_INSTANCE, GKErrorAPINotAvailable, description);
            }
///////////// command = unregisterMatchmakerCallback
        } else if(strcmp(command, "unregisterMatchmakerCallback") == 0) {
            if(self.gameCenterDelegatePtr.isRTMatchmakerCallbackRegistered == YES) {
                const char *description = "realtime matchmaker callback is unregistered";
                sendGameCenterRegisteredCallbackLuaSuccessEvent(L, GC_RT_MATCHMAKER_CALLBACK, GC_RT_MATCHMAKER_LUA_INSTANCE, description);
                unRegisterGameCenterCallbackLuaRef(L, GC_RT_MATCHMAKER_CALLBACK, GC_RT_MATCHMAKER_LUA_INSTANCE);
                self.gameCenterDelegatePtr.isRTMatchmakerCallbackRegistered = NO;
            }
            lua_settop(L, 0); // clear the whole stack
///////////// command = showMatchUI
        } else if(strcmp(command, "showMatchUI") == 0) {
            if(self.gameCenterDelegatePtr.isRTMatchmakerCallbackRegistered == YES) {
                if(self.gameCenterDelegatePtr.isMatchStarted == NO) {
                    NSUInteger minPlayers = 0;
                    lua_getfield(L, -1, "minPlayers");
                    if(lua_type(L, -1) != LUA_TNIL) {
                        luaL_checktype(L, -1, LUA_TNUMBER);
                        minPlayers = (NSUInteger) lua_tonumber(L, -1);
                        lua_pop(L, 1);
                    } else {
                        dmLogError("parameters table key 'minPlayers' expected");
                    }

                    NSUInteger maxPlayers = 0;
                    lua_getfield(L, -1, "maxPlayers");
                    if(lua_type(L, -1) != LUA_TNIL) {
                        luaL_checktype(L, -1, LUA_TNUMBER);
                        maxPlayers = (NSUInteger) lua_tonumber(L, -1);
                        lua_pop(L, 1);
                    } else {
                        dmLogError("parameters table key 'maxPlayers' expected");
                    }

                    NSUInteger defaultNumPlayers = 0;
                    lua_getfield(L, -1, "defaultNumPlayers");
                    if(lua_type(L, -1) != LUA_TNIL) {
                        luaL_checktype(L, -1, LUA_TNUMBER);
                        defaultNumPlayers = (NSUInteger) lua_tonumber(L, -1);
                        lua_pop(L, 1);
                    } else {
                        dmLogError("parameters table key 'defaultNumPlayers' expected");
                    }

                    NSUInteger playerGroup = 0;
                    BOOL playerGroupEnabled = NO;
                    lua_getfield(L, -1, "playerGroup");
                    if(lua_type(L, -1) == LUA_TNUMBER) {
                        playerGroup = (NSUInteger) lua_tonumber(L, -1);
                        playerGroupEnabled = YES;
                    }
                    // playerGroup is an optional parameter so no error if none exists
                    lua_pop(L, 1);

                    uint32_t playerAttributes = 0xFFFFFFFF;
                    BOOL playerAttributesEnabled = NO;
                    lua_getfield(L, -1, "playerAttributes");
                    if(lua_type(L, -1) == LUA_TNUMBER) {
                        playerAttributes = (uint32_t) lua_tonumber(L, -1);
                        playerAttributesEnabled = YES;
                    }
                    // playerAttributes is an optional parameter so no error if none exists
                    lua_settop(L, 0); // clear the whole stack

                    GKMatchRequest *request = [[GKMatchRequest alloc] init];
                    request.minPlayers = minPlayers;
                    request.maxPlayers = maxPlayers;
                    request.defaultNumberOfPlayers = defaultNumPlayers;
                    if ( playerGroupEnabled == YES ) {
                        request.playerGroup = playerGroup;
                    }
                    if ( playerAttributesEnabled == YES ) {
                        request.playerAttributes = playerAttributes;
                    }

                    GKMatchmakerViewController *matchmakerViewController = [[GKMatchmakerViewController alloc] initWithMatchRequest:request];
                    [request release];
                    
                    if (matchmakerViewController != nil) {
                        matchmakerViewController.matchmakerDelegate = self.gameCenterDelegatePtr;
                        [self.gameCenterDelegatePtr presentGCMatchmakerViewController:matchmakerViewController];
                    } else {
                        const char *description = [[self.gameCenterDelegatePtr stringAppendErrorDescription:@"failed to alloc GKMatchmakerViewController with GKMatchRequest"
                            errorCode:GKErrorAPINotAvailable] UTF8String];
			            sendGameCenterRegisteredCallbackLuaErrorEvent(L, GC_RT_MATCHMAKER_CALLBACK, GC_RT_MATCHMAKER_LUA_INSTANCE, GKErrorAPINotAvailable, description);
                    }
                } else {
                    lua_settop(L, 0); // clear the whole stack
                    dmLogError("There is a current match in play, cancel it before you start another match");
                }
            } else {
                lua_settop(L, 0); // clear the whole stack
                dmLogError("You must call gc_realtime( 'registerMatchmakerCallback' ) before you call gc_realtime( 'showMatchUI' )");
            }
///////////// command = showMatchWithInviteUI
        } else if(strcmp(command, "showMatchWithInviteUI") == 0) {
            if(self.gameCenterDelegatePtr.isRTMatchmakerCallbackRegistered == YES) {
                lua_settop(L, 0); // clear the whole stack
                NSLog(@"DEBUG:NSLog [RealTimeCommands.mm] showMatchWithInviteUI called");
                if(self.gameCenterDelegatePtr.currentInvite != nil) {
                    GKMatchmakerViewController *matchmakerViewController = [[GKMatchmakerViewController alloc] 
                    initWithInvite:self.gameCenterDelegatePtr.currentInvite];
                    if (matchmakerViewController != nil) {
                        matchmakerViewController.matchmakerDelegate = self.gameCenterDelegatePtr;
                        [self.gameCenterDelegatePtr presentGCMatchmakerViewController:matchmakerViewController];
                    } else {
                        const char *description = [[self.gameCenterDelegatePtr stringAppendErrorDescription:@"Failed to alloc GKMatchmakerViewController with GKInvite"
                            errorCode:GKErrorAPINotAvailable] UTF8String];
                        sendGameCenterRegisteredCallbackLuaErrorEvent(L, GC_RT_MATCHMAKER_CALLBACK, GC_RT_MATCHMAKER_LUA_INSTANCE, GKErrorAPINotAvailable, description);
                    }
                    [self.gameCenterDelegatePtr.currentInvite release];
                    self.gameCenterDelegatePtr.currentInvite = nil;
                } else {
                    const char *description = [[self.gameCenterDelegatePtr stringAppendErrorDescription:@"Game center real time match invite is nil"
                        errorCode:GKErrorInvitationsDisabled] UTF8String];
                    sendGameCenterRegisteredCallbackLuaErrorEvent(L, GC_RT_MATCHMAKER_CALLBACK, GC_RT_MATCHMAKER_LUA_INSTANCE, GKErrorInvitationsDisabled, description);
                }
            } else {
                lua_settop(L, 0); // clear the whole stack
                dmLogError("You must call gc_realtime( 'registerMatchmakerCallback' ) before you call gc_realtime( 'showMatchWithInviteUI' )");
            }
///////////// command = registerMatchCallback
        } else if(strcmp(command, "registerMatchCallback") == 0) {
            if(self.gameCenterDelegatePtr.isRTMatchCallbackRegistered == NO) {
                if(self.gameCenterDelegatePtr.isMatchStarted == YES) {
                    lua_getfield(L, -1, "callback");
                    if(lua_type(L, -1) != LUA_TNIL) {
                        if(registerGameCenterCallbackLuaRef(L, GC_RT_MATCH_CALLBACK, GC_RT_MATCH_LUA_INSTANCE)) {
                            lua_settop(L, 0); // clear the whole stack
                            const char *description = "realtime match callback is registered";
                            sendGameCenterRegisteredCallbackLuaSuccessEvent(L, GC_RT_MATCH_CALLBACK, GC_RT_MATCH_LUA_INSTANCE, description);
                            self.gameCenterDelegatePtr.isRTMatchCallbackRegistered = YES;
                        } else {
                            dmLogError("failed to register realtime callback");
                        }
                    } else {
                        dmLogError("parameters table key 'callback' expected");
                    }
                } else {
                    lua_settop(L, 0); // clear the whole stack
                    dmLogError("You must receive a 'matchStarted' event before you call gc_realtime( 'registerMatchCallback' )");
                }
            } else {
                lua_settop(L, 0); // clear the whole stack
                const char *description = [[self.gameCenterDelegatePtr stringAppendErrorDescription:@"realtime match callback is already registered"
                    errorCode:GKErrorAPINotAvailable] UTF8String];
			    sendGameCenterRegisteredCallbackLuaErrorEvent(L, GC_RT_MATCH_CALLBACK, GC_RT_MATCH_LUA_INSTANCE, GKErrorAPINotAvailable, description);
            }
///////////// command = disconnectMatch
        } else if(strcmp(command, "disconnectMatch") == 0) {
            if((self.gameCenterDelegatePtr.isMatchStarted == YES) && (self.gameCenterDelegatePtr.currentMatch != nil)) {
                [self.gameCenterDelegatePtr.currentMatch disconnect];
                self.gameCenterDelegatePtr.currentMatch.delegate = nil;
                [self.gameCenterDelegatePtr.currentMatch release];
                self.gameCenterDelegatePtr.currentMatch = nil;
                self.gameCenterDelegatePtr.isMatchStarted = NO;

                if(self.gameCenterDelegatePtr.isRTMatchCallbackRegistered == YES) {
                    lua_settop(L, 0); // clear the whole stack
                    const char *description = "realtime match is disconnected and callback unregistered";
                    sendGameCenterRegisteredCallbackLuaSuccessEvent(L, GC_RT_MATCH_CALLBACK, GC_RT_MATCH_LUA_INSTANCE, description);
                    unRegisterGameCenterCallbackLuaRef(L, GC_RT_MATCH_CALLBACK, GC_RT_MATCH_LUA_INSTANCE);
                    self.gameCenterDelegatePtr.isRTMatchCallbackRegistered = NO;
                }
            }
            lua_settop(L, 0); // clear the whole stack
///////////// command = temp
        } else if(strcmp(command, "temp") == 0) {
            // next realtime command

        } else {
            dmLogError("gc_realtime() string command expected but got %s", command);
        }
    } else {
        dmLogError("gc_realtime() requires a string command and parameters table only");
    }
}

@end