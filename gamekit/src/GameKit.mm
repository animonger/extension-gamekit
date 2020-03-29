// Apple GameKit Defold Extension
// GameKit.mm

#include <stdio.h>
#include <dmsdk/sdk.h>
#include "LuaEvents.h"
// #include "LuaStackDump.h"

#import <GameKit/GameKit.h>
#import "GameKit.h"
#import "GameCenterDelegate.h"
#import "SendCommands.h"
#import "GetCommands.h"
#import "ShowCommands.h"
#import "RealTimeCommands.h"

// file-static variables
// static bool is_ARC_Enabled = false; // temp bool for debugging


// class pointers
GameCenterDelegate *gameCenterDelegatePtr;
SendCommands *sendCommandsPtr;
GetCommands *getCommandsPtr;
ShowCommands *showCommandsPtr;
RealTimeCommands *realTimeCommandsPtr;

// #if __has_feature(objc_arc)
//     is_ARC_Enabled = true;
// #endif

void gameCenterRealTimeCommand(lua_State *L)
{
	NSLog(@"DEBUG:NSLog [GameKit.mm] gameCenterRealTimeCommand called");
	if(gameCenterDelegatePtr.isGameCenterEnabled == YES) {
		[realTimeCommandsPtr gcRealTimeCommandFromLuaState:L];
	} else {
		dmLogError("Game Center not enabled, you must call gc_signin() before you call gc_realtime()");
	}
}

void gameCenterShowCommand(lua_State *L)
{
	// NSLog(@"DEBUG:NSLog [GameKit.mm] gameCenterShowCommand called");
	if(gameCenterDelegatePtr.isGameCenterEnabled == YES) {
		[showCommandsPtr gcShowCommandFromLuaState:L];
	} else {
		dmLogError("Game Center not enabled, you must call gc_signin() before you call gc_show()");
	}
}

void gameCenterGetCommand(lua_State *L)
{
	// NSLog(@"DEBUG:NSLog [GameKit.mm] gameCenterGetCommand called");
	if(gameCenterDelegatePtr.isGameCenterEnabled == YES) {
		[getCommandsPtr gcGetCommandFromLuaState:L];
	} else {
		dmLogError("Game Center not enabled, you must call gc_signin() before you call gc_get()");
	}
}

void gameCenterSendCommand(lua_State *L)
{	
	// NSLog(@"DEBUG:NSLog [GameKit.mm] gameCenterSendCommand called");
	if(gameCenterDelegatePtr.isGameCenterEnabled == YES) {
		[sendCommandsPtr gcSendCommandFromLuaState:L];
	} else {
		dmLogError("Game Center not enabled, you must call gc_signin() before you call gc_send()");
	}
}

static void presentGameCenterSignInView()
{
	// NSLog(@"DEBUG:NSLog [GameKit.mm] presentGameCenterSignInView called");
#if defined(DM_PLATFORM_IOS)
	// below is needed to present the authenticate view controller in ios.
    [[[UIApplication sharedApplication] keyWindow].rootViewController presentViewController:
		gameCenterDelegatePtr.authenticateViewController animated:YES completion:nil];
#else // osx platform
	// below is the recomended way to present the authenticate view controller in osx/macOS but in osx 10.11.6, the game center app overrides it.
	// keeping code active encase other versions of osx/macOS use this method of presenting the authenticate view controller.
	[[[NSApplication sharedApplication] keyWindow].windowController.contentViewController 
		presentViewControllerAsModalWindow:gameCenterDelegatePtr.authenticateViewController];
#endif
}

void gameCenterShowSignInUI(lua_State *L)
{
	// NSLog(@"DEBUG:NSLog [GameKit.mm] gameCenterShowSignInUI called");
	const char *parameter = lua_tostring( L, 1 );
	if(strcmp(parameter, "UI") == 0) {
		if(gameCenterDelegatePtr.authenticateViewController != nil) {
			// show game center signin view controller
			presentGameCenterSignInView();
		} else {
			dmLogError("You must receive the 'showSignInUI' event before you call gc_show_signin('UI')");
		}
	} else {
		dmLogError("String parameter 'UI' expected but got %s", parameter);
	}
	lua_pop(L, 1);
}

static void gameCenterAuthentication(lua_State *L)
{
	// NSLog(@"DEBUG:NSLog [GameKit.mm] gameCenterAuthentication called");
	// game center authentication for localPlayer
	[GKLocalPlayer localPlayer].authenticateHandler = ^(UIViewController *viewController, NSError *error) {
		// NSLog(@"DEBUG:NSLog [GameKit.mm] gameCenterAuthentication error = %@", error);
		// NSLog(@"DEBUG:NSLog [GameKit.mm] gameCenterAuthentication [GKLocalPlayer localPlayer] = %@", [GKLocalPlayer localPlayer]);
		if(viewController != nil) {
			// player not logged in yet, send lua event and store game center sign in UI
			gameCenterDelegatePtr.authenticateViewController = viewController;
			gameCenterDelegatePtr.isGameCenterEnabled = NO;
			lua_newtable(L); // create lua table for event
			// push items and set feilds
			lua_pushstring(L, "showSignInUI");
			lua_setfield(L, -2, "type");
			lua_pushstring(L, "Local Player not signed in, show Game Center Sign In UI when convenient.");
			lua_setfield(L, -2, "description");
			// store reference to lua event table
			int luaTableRef = dmScript::Ref(L, LUA_REGISTRYINDEX);
			sendGameCenterRegisteredCallbackLuaEvent(L, GC_SIGN_IN_CALLBACK, GC_SIGN_IN_LUA_INSTANCE, luaTableRef);
		} else if([GKLocalPlayer localPlayer].isAuthenticated == YES && [error code] != GKErrorCancelled) {
			// authentication successful, send event to lua
			gameCenterDelegatePtr.isGameCenterEnabled = YES;
			lua_newtable(L); // create lua table for event
			// push items and set feilds
			lua_pushstring(L, "authenticated");
			lua_setfield(L, -2, "type");
			lua_pushstring(L, [[GKLocalPlayer localPlayer].playerID UTF8String]);
			lua_setfield(L, -2, "localPlayerID");
			lua_pushstring(L, [[GKLocalPlayer localPlayer].alias UTF8String]);
			lua_setfield(L, -2, "localPlayerAlias");
			lua_pushboolean(L, [GKLocalPlayer localPlayer].isUnderage);
			lua_setfield(L, -2, "localPlayerIsUnderage");
			// store reference to lua event table
			int luaTableRef = dmScript::Ref(L, LUA_REGISTRYINDEX);
			sendGameCenterRegisteredCallbackLuaEvent(L, GC_SIGN_IN_CALLBACK, GC_SIGN_IN_LUA_INSTANCE, luaTableRef);
			if(gameCenterDelegatePtr.authenticateViewController != nil) {
        		gameCenterDelegatePtr.authenticateViewController = nil;
    		}
		} else {
			gameCenterDelegatePtr.isGameCenterEnabled = NO;
			const char *description = [[gameCenterDelegatePtr stringAppendErrorDescription:[error localizedDescription] 
            errorCode:[error code]] UTF8String];
			sendGameCenterRegisteredCallbackLuaErrorEvent(L, GC_SIGN_IN_CALLBACK, GC_SIGN_IN_LUA_INSTANCE, [error code], description);
			// after the local player cancels the sign in ui 3 times game center ignores authentication until the local player 
			// signs into game center through the device's game center settings.
		}
	};
}

void gameCenterSignIn(lua_State *L)
{
	// NSLog(@"DEBUG:NSLog [GameKit.mm] gameCenterSignIn called");
	// if(is_ARC_Enabled) {
	// 	NSLog(@"DEBUG:NSLog [GameKit.mm] --------- ARC is ON");
	// } else {
	// 	NSLog(@"DEBUG:NSLog [GameKit.mm] --------- ARC is OFF");
	// }
	
	// intitialize GameCenterDelegate and commands classes once
	if(gameCenterDelegatePtr == nil) {
		if(registerGameCenterCallbackLuaRef(L, GC_SIGN_IN_CALLBACK, GC_SIGN_IN_LUA_INSTANCE)) {
			gameCenterDelegatePtr = [[GameCenterDelegate alloc] init];
			// set GameCenterDelegate BOOLs to NO
			gameCenterDelegatePtr.isGameCenterEnabled = NO;
			gameCenterDelegatePtr.isLocalPlayerListenerRegistered = NO;
			gameCenterDelegatePtr.isRTMatchmakerCallbackRegistered = NO;
			gameCenterDelegatePtr.isMatchStarted = NO;
			
			// initialize the commands classes with the gameCenterDelegatePtr
			sendCommandsPtr = [[SendCommands alloc] initWithGameCenterDelegate:gameCenterDelegatePtr];
			getCommandsPtr = [[GetCommands alloc] initWithGameCenterDelegate:gameCenterDelegatePtr];
			showCommandsPtr = [[ShowCommands alloc] initWithGameCenterDelegate:gameCenterDelegatePtr];
			realTimeCommandsPtr = [[RealTimeCommands alloc] initWithGameCenterDelegate:gameCenterDelegatePtr];

			// call game center authentication for localPlayer
			gameCenterAuthentication(L);
		} else {
			dmLogError("failed to register signin callback");
		}
	} else {
		dmLogError("Game Center is enabled, call gc_signin() only one time after your game launches");
	}
}

void finalizeGameKit(lua_State *L)
{
	// NSLog(@"DEBUG:NSLog [GameKit.mm] finalizeGameKit called");
	unRegisterGameCenterCallbackLuaRef(L, GC_SIGN_IN_CALLBACK, GC_SIGN_IN_LUA_INSTANCE);
	if(gameCenterDelegatePtr.isRTMatchmakerCallbackRegistered == YES) {
		unRegisterGameCenterCallbackLuaRef(L, GC_RT_MATCHMAKER_CALLBACK, GC_RT_MATCHMAKER_LUA_INSTANCE);
		gameCenterDelegatePtr.isRTMatchmakerCallbackRegistered = NO;
	}
	[[GKLocalPlayer localPlayer] unregisterAllListeners];

	// release the Commands
	if(sendCommandsPtr != nil) {
		[sendCommandsPtr release];
    	sendCommandsPtr = nil;
	}
	if(getCommandsPtr != nil) {
		[getCommandsPtr release];
    	getCommandsPtr = nil;
	}

	if(showCommandsPtr != nil) {
		[showCommandsPtr release];
    	showCommandsPtr = nil;
	}

	if(realTimeCommandsPtr != nil) {
		[realTimeCommandsPtr release];
    	realTimeCommandsPtr = nil;
	}

	// release GameCenterDelegate
	if(gameCenterDelegatePtr != nil) {
		[gameCenterDelegatePtr release];
    	gameCenterDelegatePtr = nil;
	}
}
