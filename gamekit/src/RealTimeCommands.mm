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
            if(self.gameCenterDelegatePtr.isRTMatchmakerCallbackEnabled == NO) {
                // add error check to registerGameCenterCallback
                lua_getfield(L, -1, "callback");
                if(lua_type(L, -1) != LUA_TNIL) {
                    if(registerGameCenterCallbackLuaRef(L, GC_RT_MATCHMAKER_CALLBACK, GC_RT_MATCHMAKER_LUA_INSTANCE)) {
                        lua_settop(L, 0); // clear the whole stack
                        
                        // register matchmaker objective c code here

                        lua_newtable(L); // create lua table for event
                        // push items and set feilds
                        lua_pushstring(L, "success");
                        lua_setfield(L, -2, "type");
                        lua_pushstring(L, "realtime matchmaker callback is registered");
                        lua_setfield(L, -2, "description");
                        // store reference to lua event table
                        int luaTableRef = dmScript::Ref(L, LUA_REGISTRYINDEX);
                        sendGameCenterRegisteredCallbackLuaEvent(L, GC_RT_MATCHMAKER_CALLBACK, GC_RT_MATCHMAKER_LUA_INSTANCE, luaTableRef);
                        self.gameCenterDelegatePtr.isRTMatchmakerCallbackEnabled = YES;
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