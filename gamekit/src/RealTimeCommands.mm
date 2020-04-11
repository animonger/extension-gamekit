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
///////////// command = rttemp
        if(strcmp(command, "rttemp") == 0) {
            // realtime listner command here
///////////// command = registerMatchmakerCallback
        } else if(strcmp(command, "registerMatchmakerCallback") == 0) {
            if(self.gameCenterDelegatePtr.isRTMatchmakerCallbackRegistered == NO) {
                // add error check to registerGameCenterCallback
                lua_getfield(L, -1, "callback");
                if(lua_type(L, -1) != LUA_TNIL) {
                    if(registerGameCenterCallbackLuaRef(L, GC_RT_MATCHMAKER_CALLBACK, GC_RT_MATCHMAKER_LUA_INSTANCE)) {
                        lua_settop(L, 0); // clear the whole stack
                        lua_newtable(L); // create lua table for event
                        // push items and set feilds
                        lua_pushstring(L, "success");
                        lua_setfield(L, -2, "type");
                        lua_pushstring(L, "realtime matchmaker callback is registered");
                        lua_setfield(L, -2, "description");
                        // store reference to lua event table
                        int luaTableRef = dmScript::Ref(L, LUA_REGISTRYINDEX);
                        sendGameCenterRegisteredCallbackLuaEvent(L, GC_RT_MATCHMAKER_CALLBACK, GC_RT_MATCHMAKER_LUA_INSTANCE, luaTableRef);
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