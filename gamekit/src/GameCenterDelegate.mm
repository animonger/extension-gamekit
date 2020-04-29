// Apple GameKit Defold Extension
// GameCenterDelegate.mm

#include <stdio.h>
#include <dmsdk/sdk.h>
#include "LuaEvents.h"
#include "LuaStackDump.h"

#import <GameKit/GameKit.h>
#import "GameCenterDelegate.h"
#import "ImageBitmap.h"

@implementation GameCenterDelegate

// hide game center leaderboards and achievements UI
- (void)gameCenterViewControllerDidFinish:(GKGameCenterViewController *)gameCenterViewController
{
    // NSLog(@"DEBUG:NSLog [GameCenterDelegate.mm] gameCenterViewControllerDidFinish: Hide Game Center UI");
#if defined(DM_PLATFORM_IOS)
    [gameCenterViewController dismissViewControllerAnimated:YES completion:nil];
#else // osx platform
    [[GKDialogController sharedDialogController] dismiss: gameCenterViewController];
#endif
	[gameCenterViewController release];
}

- (void)presentGameCenterViewController:(GKGameCenterViewController *)gameCenterViewController
{
	// NSLog(@"DEBUG:NSLog [GameCenterDelegate.mm] presentGameCenterViewController called");
#if defined(DM_PLATFORM_IOS)
	[[[UIApplication sharedApplication] keyWindow].rootViewController presentViewController:gameCenterViewController animated:YES completion:nil];
#else // osx platform
	[GKDialogController sharedDialogController].parentWindow = [[NSApplication sharedApplication] mainWindow];
	[[GKDialogController sharedDialogController] presentViewController:gameCenterViewController];
#endif
}

// the player has cancelled matchmaking
- (void)matchmakerViewControllerWasCancelled:(GKMatchmakerViewController *)matchmakerViewController
{
    //NSLog(@"DEBUG:NSLog [GameCenterDelegate.mm] matchmakerViewControllerWasCancelled called");
#if defined(DM_PLATFORM_IOS)
    [matchmakerViewController dismissViewControllerAnimated:YES completion:nil];
#else // osx platform
    [[GKDialogController sharedDialogController] dismiss: matchmakerViewController];
#endif
	[matchmakerViewController release];
}

// a peer-to-peer real-time match has been found, the game should start
- (void)matchmakerViewController:(GKMatchmakerViewController *)matchmakerViewController didFindMatch:(GKMatch *)match
{
	// NSLog(@"DEBUG:NSLog [GameCenterDelegate.mm] matchmakerViewController didFindMatch called");
#if defined(DM_PLATFORM_IOS)
    [matchmakerViewController dismissViewControllerAnimated:YES completion:nil];
#else // osx platform
    [[GKDialogController sharedDialogController] dismiss: matchmakerViewController];
#endif
	[matchmakerViewController release];

    if ((self.isMatchStarted == NO) && (self.isRTMatchmakerCallbackRegistered == YES)) {
		self.currentMatch = [match retain]; // retain the match object
		self.currentMatch.delegate = self;
		self.isMatchStarted = YES;
		NSInteger playersCount = [match players].count;
		//NSLog(@"DEBUG:NSLog [GameCenterDelegate.mm] playersCount = %zd", playersCount);

        lua_State *L = dmScript::GetMainThread(self.luaStatePtr);
		lua_settop(L, 0); // clear the whole stack
		lua_newtable(L); // create lua table for event
		// push items and set feilds
		lua_pushstring(L, "matchStarted");
		lua_setfield(L, -2, "type");
		// expectedPlayerCount, The remaining number of players who have not yet connected to the match.
		lua_pushinteger(L, match.expectedPlayerCount);
		lua_setfield(L, -2, "expectedPlayerCount");
		lua_pushinteger(L, playersCount);
		lua_setfield(L, -2, "playersCount");
		lua_newtable(L); // create lua table for players

		int i = 1;
		for (GKPlayer *player in [match players]) {
			lua_pushinteger(L, i);
			[self newLuaTableFromPlayerObject:player luaState:L];
			lua_settable(L, -3);
			i++;
		}
		lua_setfield(L, -2, "players"); // add players table to event table

		// store reference to lua event table
		int luaTableRef = dmScript::Ref(L, LUA_REGISTRYINDEX);
		sendGameCenterRegisteredCallbackLuaEvent(L, GC_RT_MATCHMAKER_CALLBACK, GC_RT_MATCHMAKER_LUA_INSTANCE, luaTableRef);
    }
}

// matchmaking has failed with an error
- (void)matchmakerViewController:(GKMatchmakerViewController *)matchmakerViewController didFailWithError:(NSError *)error
{
	//NSLog(@"DEBUG:NSLog [GameCenterDelegate.mm] matchmakerViewController didFailWithError called");
#if defined(DM_PLATFORM_IOS)
    [matchmakerViewController dismissViewControllerAnimated:YES completion:nil];
#else // osx platform
    [[GKDialogController sharedDialogController] dismiss: matchmakerViewController];
#endif
	[matchmakerViewController release];

    if(self.currentMatch != nil) {
        self.currentMatch.delegate = nil;
        [self.currentMatch release];
        self.currentMatch = nil;
    }

	if(self.isRTMatchmakerCallbackRegistered == YES) {
		lua_State *L = dmScript::GetMainThread(self.luaStatePtr);
		lua_settop(L, 0); // clear the whole stack
		const char *description = [[self stringAppendErrorDescription:[error localizedDescription] errorCode:[error code]] UTF8String];
		sendGameCenterRegisteredCallbackLuaErrorEvent(L, GC_RT_MATCHMAKER_CALLBACK, GC_RT_MATCHMAKER_LUA_INSTANCE, [error code], description);
	}
}

// called on localPlayer device after localPlayer accepts friend invite
- (void)player:(GKPlayer *)player didAcceptInvite:(GKInvite *)invite
{
	// NSLog(@"DEBUG:NSLog [GameCenterDelegate.mm] player didAcceptInvite called");
	self.currentInvite = [invite retain]; // retain the invite object
	
	if(self.isRTMatchmakerCallbackRegistered == YES) {
    	lua_State *L = dmScript::GetMainThread(self.luaStatePtr);
		lua_settop(L, 0); // clear the whole stack
		lua_newtable(L); // create lua table for event
		lua_pushstring(L, "acceptedInvite");
		lua_setfield(L, -2, "type");
		// store reference to lua event table
		int luaTableRef = dmScript::Ref(L, LUA_REGISTRYINDEX);
		sendGameCenterRegisteredCallbackLuaEvent(L, GC_RT_MATCHMAKER_CALLBACK, GC_RT_MATCHMAKER_LUA_INSTANCE, luaTableRef);
	}
}


- (void)presentGCMatchmakerViewController:(GKMatchmakerViewController *)matchmakerViewController
{
	//NSLog(@"DEBUG:NSLog [GameCenterDelegate.mm] presentGCMatchmakerViewController called");
#if defined(DM_PLATFORM_IOS)
	[[[UIApplication sharedApplication] keyWindow].rootViewController presentViewController:matchmakerViewController animated:YES completion:nil];
#else // osx platform
	[GKDialogController sharedDialogController].parentWindow = [[NSApplication sharedApplication] mainWindow];
	[[GKDialogController sharedDialogController] presentViewController:matchmakerViewController];
#endif
}

// iOS 8 and above
- (void)match:(GKMatch *)match didReceiveData:(NSData *)data fromRemotePlayer:(GKPlayer *)player
{
	//NSLog(@"DEBUG:NSLog [GameCenterDelegate.mm] didReceiveData fromRemotePlayer called");
	[self sendMatchData:data fromPlayer:player];
}

// iOS 9 and above
- (void)match:(GKMatch *)match didReceiveData:(NSData *)data forRecipient:(GKPlayer *)recipient fromRemotePlayer:(GKPlayer *)player
{
	//NSLog(@"DEBUG:NSLog [GameCenterDelegate.mm] didReceiveData forRecipient fromRemotePlayer called");
	[self sendMatchData:data fromPlayer:player];
}

- (void)match:(GKMatch *)match player:(GKPlayer *)player didChangeConnectionState:(GKPlayerConnectionState)state
{
	//NSLog(@"DEBUG:NSLog [GameCenterDelegate.mm] match player didChangeConnectionState isMatchStarted = %@", self.isMatchStarted ? @"YES" : @"NO");
	switch(state)
	{
		case GKPlayerStateConnected:  // Added player is connected to the match and can receive data. 
			//NSLog(@"DEBUG:NSLog [GameCenterDelegate.mm] GKPlayerStateConnected match = %@,  player = %@", match, player);
			if(self.isRTMatchmakerCallbackRegistered == YES) {
				lua_State *L = dmScript::GetMainThread(self.luaStatePtr);
				lua_settop(L, 0); // clear the whole stack
				[self newLuaTableFromPlayerObject:player luaState:L];
				// push items and set feilds
				lua_pushstring(L, "playerAddedToMatch");
				lua_setfield(L, -2, "type");
				// expectedPlayerCount, The remaining number of players who have not yet connected to the match.
				lua_pushinteger(L, match.expectedPlayerCount);
				lua_setfield(L, -2, "expectedPlayerCount");
				lua_pushinteger(L, [match players].count);
				lua_setfield(L, -2, "playersCount");
				
				// store reference to lua event table
				int luaTableRef = dmScript::Ref(L, LUA_REGISTRYINDEX);
				sendGameCenterRegisteredCallbackLuaEvent(L, GC_RT_MATCHMAKER_CALLBACK, GC_RT_MATCHMAKER_LUA_INSTANCE, luaTableRef);
			}
			break;

		case GKPlayerStateDisconnected:  // The player is disconnected from the match and cannot receive data.
			//NSLog(@"DEBUG:NSLog [GameCenterDelegate.mm] GKPlayerStateDisconnected match = %@,  player = %@", match, player);
			if(self.isRTMatchCallbackRegistered == YES) {
				lua_State *L = dmScript::GetMainThread(self.luaStatePtr);
				lua_settop(L, 0); // clear the whole stack
				[self newLuaTableFromPlayerObject:player luaState:L];
				// push items and set feilds
				lua_pushstring(L, "playerStateDisconnected");
				lua_setfield(L, -2, "type");
				// store reference to lua event table
				int luaTableRef = dmScript::Ref(L, LUA_REGISTRYINDEX);
				sendGameCenterRegisteredCallbackLuaEvent(L, GC_RT_MATCH_CALLBACK, GC_RT_MATCH_LUA_INSTANCE, luaTableRef);
			}
			break;

		case GKPlayerStateUnknown:  // The player is in an indeterminate state and cannot receive data.
			//NSLog(@"DEBUG:NSLog [GameCenterDelegate.mm] GKPlayerStateUnknown match = %@,  player = %@", match, player);
			if(self.isRTMatchCallbackRegistered == YES) {
				lua_State *L = dmScript::GetMainThread(self.luaStatePtr);
				lua_settop(L, 0); // clear the whole stack
				[self newLuaTableFromPlayerObject:player luaState:L];
				// push items and set feilds
				lua_pushstring(L, "playerStateUnknown");
				lua_setfield(L, -2, "type");
				// store reference to lua event table
				int luaTableRef = dmScript::Ref(L, LUA_REGISTRYINDEX);
				sendGameCenterRegisteredCallbackLuaEvent(L, GC_RT_MATCH_CALLBACK, GC_RT_MATCH_LUA_INSTANCE, luaTableRef);
			}
			break;
	}
}

// called when realtime match cannot connect to any other players. it usually means a serious networking error has occurred
- (void)match:(GKMatch *)match didFailWithError:(NSError *)error
{
	//NSLog(@"DEBUG:NSLog [GameCenterDelegate.mm] match didFailWithError called");
	if(self.isRTMatchCallbackRegistered == YES) {
		lua_State *L = dmScript::GetMainThread(self.luaStatePtr);
		lua_settop(L, 0); // clear the whole stack
		const char *description = [[self stringAppendErrorDescription:[error localizedDescription] errorCode:[error code]] UTF8String];
		sendGameCenterRegisteredCallbackLuaErrorEvent(L, GC_RT_MATCH_CALLBACK, GC_RT_MATCH_LUA_INSTANCE, [error code], description);
		if(self.currentMatch != nil) {
			[self.currentMatch disconnect];
			self.currentMatch.delegate = nil;
			[self.currentMatch release];
			self.currentMatch = nil;
		}
		if(self.isMatchStarted == YES) {
			self.isMatchStarted = NO;
		}
		description = "realtime match is disconnected and callback unregistered";
		sendGameCenterRegisteredCallbackLuaSuccessEvent(L, GC_RT_MATCH_CALLBACK, GC_RT_MATCH_LUA_INSTANCE, description);
		unRegisterGameCenterCallbackLuaRef(L, GC_RT_MATCH_CALLBACK, GC_RT_MATCH_LUA_INSTANCE);
		self.isRTMatchCallbackRegistered = NO;
	}
}

- (NSString *)stringAppendErrorDescription:(NSString *)errorDescription errorCode:(NSInteger)errorCode
{
	NSString *description = nil;        
    // the most common error codes from 1 to 31 are converted to strings within the gkErrorCodes array for lua developer convenience
	if((errorCode > 0) && (errorCode < 32)) {
		description = [[NSString stringWithUTF8String:gkErrorCodes[errorCode]] stringByAppendingString:errorDescription];
	} else {
		// error codes outside of 1 to 31 are not translated and sent with the localizedDescription
		description = errorDescription;
	}
	return description;
}

- (NSInteger)newLuaTableFromScoreObject:(GKScore *)score luaState:(lua_State *)L
{
	//NSLog(@"DEBUG:NSLog [GameCenterDelegate.mm] newLuaTableFromScoreObject score = %@", score);
	lua_newtable(L); // create lua table for score object
	lua_pushstring(L, [[score player].alias UTF8String]);
	lua_setfield(L, -2, "playerAlias");
	lua_pushstring(L, [[score player].displayName UTF8String]);
	lua_setfield(L, -2, "playerDisplayName");
	lua_pushstring(L, [[score player].playerID UTF8String]);
	lua_setfield(L, -2, "playerID");
	lua_pushstring(L, [[score leaderboardIdentifier] UTF8String]);
	lua_setfield(L, -2, "leaderboardID");
	lua_pushinteger(L, [score rank]);
    lua_setfield(L, -2, "rank");
	lua_pushstring(L, [[score formattedValue] UTF8String]);
	lua_setfield(L, -2, "formattedValue");
	lua_pushinteger(L, [score value]);
    lua_setfield(L, -2, "value");
	lua_pushinteger(L, [score context]);
    lua_setfield(L, -2, "context");
	lua_pushstring(L, [[score date].description UTF8String]);
	lua_setfield(L, -2, "date");
	return 1;
}

- (NSInteger)newLuaTableFromLeaderboardObject:(GKLeaderboard *)leaderboard luaState:(lua_State *)L
{
	//NSLog(@"DEBUG:NSLog [GameCenterDelegate.mm] newLuaTableFromLeaderboardObject leaderboard = %@", leaderboard);
	lua_newtable(L); // create lua table for leaderboard object
	lua_pushstring(L, [[leaderboard title] UTF8String]);
	lua_setfield(L, -2, "leaderboardTitle");
	lua_pushstring(L, [[leaderboard identifier] UTF8String]);
	lua_setfield(L, -2, "leaderboardID");
	if([leaderboard groupIdentifier] != nil) {
		lua_pushstring(L, [[leaderboard groupIdentifier] UTF8String]);
	} else {
		lua_pushnil(L);
	}
	lua_setfield(L, -2, "leaderboardGroupID");
	return 1;
}

- (NSInteger)newLuaTableFromLeaderboardSetObject:(GKLeaderboardSet *)leaderboardSet luaState:(lua_State *)L
{
	//NSLog(@"DEBUG:NSLog [GameCenterDelegate.mm] newLuaTableFromLeaderboardSetObject leaderboardSet = %@", leaderboardSet);
	lua_newtable(L); // create lua table for leaderboard set object
	lua_pushstring(L, [[leaderboardSet title] UTF8String]);
	lua_setfield(L, -2, "leaderboardSetTitle");
	lua_pushstring(L, [[leaderboardSet identifier] UTF8String]);
	lua_setfield(L, -2, "leaderboardSetID");
	if([leaderboardSet groupIdentifier] != nil) {
		lua_pushstring(L, [[leaderboardSet groupIdentifier] UTF8String]);
	} else {
		lua_pushnil(L);
	}
	lua_setfield(L, -2, "leaderboardSetGroupID");
	return 1;
}

- (NSInteger)newLuaTableFromAchievementObject:(GKAchievement *)achievement luaState:(lua_State *)L
{
	//NSLog(@"DEBUG:NSLog [GameCenterDelegate.mm] newLuaTableFromAchievementObject achievement = %@", achievement);
	lua_newtable(L); // create lua table for achievement object
	lua_pushstring(L, [[achievement player].alias UTF8String]);
	lua_setfield(L, -2, "playerAlias");
	lua_pushstring(L, [[achievement player].displayName UTF8String]);
	lua_setfield(L, -2, "playerDisplayName");
	lua_pushstring(L, [[achievement player].playerID UTF8String]);
	lua_setfield(L, -2, "playerID");
	lua_pushstring(L, [[achievement identifier] UTF8String]);
	lua_setfield(L, -2, "achievementID");
	lua_pushboolean(L, [achievement isCompleted]);
	lua_setfield(L, -2, "isCompleted");
	lua_pushnumber(L, [achievement percentComplete]);
	lua_setfield(L, -2, "percentComplete");
	lua_pushboolean(L, [achievement showsCompletionBanner]);
	lua_setfield(L, -2, "showsCompletionBanner");
	lua_pushstring(L, [[achievement lastReportedDate].description UTF8String]);
	lua_setfield(L, -2, "lastReportedDate");
	return 1;
}

- (NSInteger)newLuaTableFromAchievementDescriptionObject:(GKAchievementDescription *)achvDescription luaState:(lua_State *)L
{
	//NSLog(@"DEBUG:NSLog [GameCenterDelegate.mm] newLuaTableFromAchievementDescriptionObject achvDescription = %@", achvDescription);
	lua_newtable(L); // create lua table for achievement description object
	lua_pushstring(L, [[achvDescription title] UTF8String]);
	lua_setfield(L, -2, "achievementTitle");
	lua_pushstring(L, [[achvDescription identifier] UTF8String]);
	lua_setfield(L, -2, "achievementID");
	if([achvDescription groupIdentifier] != nil) {
		lua_pushstring(L, [[achvDescription groupIdentifier] UTF8String]);
	} else {
		lua_pushnil(L);
	}
	lua_setfield(L, -2, "achievementGroupID");
	lua_pushstring(L, [[achvDescription unachievedDescription] UTF8String]);
	lua_setfield(L, -2, "unachievedDescription");
	lua_pushstring(L, [[achvDescription achievedDescription] UTF8String]);
	lua_setfield(L, -2, "achievedDescription");
	lua_pushinteger(L, [achvDescription maximumPoints]);
    lua_setfield(L, -2, "maximumPoints");
	lua_pushboolean(L, [achvDescription isHidden]);
	lua_setfield(L, -2, "isHidden");
	lua_pushboolean(L, [achvDescription isReplayable]);
	lua_setfield(L, -2, "isReplayable");
	return 1;
}

- (NSInteger)newLuaTableFromPlayerObject:(GKPlayer *)player luaState:(lua_State *)L
{
	lua_newtable(L); // create lua table for player object
	lua_pushstring(L, [[player alias] UTF8String]);
	lua_setfield(L, -2, "playerAlias");
	lua_pushstring(L, [[player displayName] UTF8String]);
	lua_setfield(L, -2, "playerDisplayName");
	lua_pushstring(L, [[player playerID] UTF8String]);
	lua_setfield(L, -2, "playerID");
	return 1;
}

- (NSString *)getLeaderboardIDFromLuaState:(lua_State *)L
{
	NSString *leaderboardID = nil;
	lua_getfield(L, -1, "leaderboardID");
	if(lua_type(L, -1) != LUA_TNIL) {
		luaL_checktype(L, -1, LUA_TSTRING);
		leaderboardID = [NSString stringWithUTF8String:lua_tostring(L, -1)];
		lua_pop(L, 1);
	} else {
		dmLogError("parameters table key 'leaderboardID' expected");
	}
	return leaderboardID;
}

- (GKLeaderboardTimeScope)getLeaderboardTimeScopeFromLuaState:(lua_State *)L
{
	GKLeaderboardTimeScope timeScope = GKLeaderboardTimeScopeAllTime;
	lua_getfield( L, -1, "timeScope" );
	if(lua_type(L, -1) != LUA_TNIL) {
		luaL_checktype(L, -1, LUA_TSTRING);
		const char *scope = lua_tostring(L, -1);
		if (strcmp(scope, "Today" ) == 0) {
			timeScope = GKLeaderboardTimeScopeToday;
		} else if (strcmp( scope, "Week") == 0) {
			timeScope = GKLeaderboardTimeScopeWeek;
		} else if (strcmp( scope, "AllTime") == 0) {
			timeScope = GKLeaderboardTimeScopeAllTime;
		} else {
			dmLogError("parameter string 'Today' or 'Week' or 'AllTime' expected but got %s", scope);
		}
		lua_pop(L, 1);
	} else {
		dmLogError("parameters table key 'timeScope' expected");
	}
	return timeScope;
}

- (NSInteger)newLuaTableFromBitmap:(unsigned char *)bitmap width:(size_t)width height:(size_t)height luaState:(lua_State *)L
{
	dmBuffer::HBuffer buffer; // create buffer
	dmBuffer::StreamDeclaration streams_decl[] = { {dmHashString64("pixels"), dmBuffer::VALUE_TYPE_UINT8, 4} };
	NSInteger result = 0;
	dmBuffer::Result createResult = dmBuffer::Create(width * height, streams_decl, 1, &buffer);
	if (createResult == dmBuffer::RESULT_OK) {
		// copy pixels into buffer
		uint8_t *bytes = 0x0;
		uint32_t size = 0;
		dmBuffer::GetBytes(buffer, (void**)&bytes, &size);
		memcpy(bytes, bitmap, size);
		// validate and push to lua image table
		if (dmBuffer::ValidateBuffer(buffer) == dmBuffer::RESULT_OK) {
			dmScript::LuaHBuffer luabuffer = { buffer, true };

			lua_newtable(L); // create lua table for image
			dmScript::PushBuffer(L, luabuffer);
			lua_setfield(L, -2, "buffer");
			lua_pushnumber(L, width);
			lua_setfield(L, -2, "width");
			lua_pushnumber(L, height);
			lua_setfield(L, -2, "height");
			result = 1;
		} else {
			dmLogError("dmBuffer::ValidateBuffer buffer NOT valid");
		}
	} else {
		dmLogError("dmBuffer::Create buffer NOT created");
	}
	
	return result;
}

- (void)sendMatchData:(NSData *)data fromPlayer:(GKPlayer *)player
{
	//NSLog(@"DEBUG:NSLog [GameCenterDelegate.mm] sendMatchData fromPlayer called");
	if(self.isRTMatchCallbackRegistered == YES) {
		lua_State *L = dmScript::GetMainThread(self.luaStatePtr);
		lua_settop(L, 0); // clear the whole stack
		[self newLuaTableFromPlayerObject:player luaState:L];
		
		const char *dataUTF8String = (const char*) [data bytes];
		// needs further testing, if above corrupts the data use code below instead
		// NSString *dataString = [[NSString alloc] initWithData:matchData encoding:NSUTF8StringEncoding];
		// need to release NSString after lua_pushstring()
		lua_pushstring(L, dataUTF8String);
		lua_setfield(L, -2, "data");
		lua_pushstring(L, "matchData");
		lua_setfield(L, -2, "type");
		// store reference to lua event table
		int luaTableRef = dmScript::Ref(L, LUA_REGISTRYINDEX);
		sendGameCenterRegisteredCallbackLuaEvent(L, GC_RT_MATCH_CALLBACK, GC_RT_MATCH_LUA_INSTANCE, luaTableRef);
	}
}

- (void)sendImageFromLeaderboard:(GKLeaderboard *)leaderboard luaCallbackRef:(NSInteger)cbRef luaSelfRef:(NSInteger)selfRef luaState:(lua_State *)L
{
#if defined(DM_PLATFORM_IOS)
	[leaderboard loadImageWithCompletionHandler:^(UIImage *image, NSError *error) {
#else // osx platform
	[leaderboard loadImageWithCompletionHandler:^(NSImage *image, NSError *error) {
#endif
		//NSLog(@"DEBUG:NSLog [GameCenterDelegate.mm] sendImageFromLeaderboard error = %@", error);
		//NSLog(@"DEBUG:NSLog [GameCenterDelegate.mm] sendImageFromLeaderboard image = %@", image);
		if(error) {
			const char *description = [[self stringAppendErrorDescription:[error localizedDescription]
				errorCode:[error code]] UTF8String];
			sendGameCenterCallbackLuaErrorEvent(L, cbRef, selfRef, [error code], description);
		} else if(error == nil && image == nil) {
			const char *description = [[self stringAppendErrorDescription:@"Game Center Leaderboard has no image" 
				errorCode:GKErrorInvalidParameter] UTF8String];
			sendGameCenterCallbackLuaErrorEvent(L, cbRef, selfRef, GKErrorInvalidParameter, description);
		} else {
			lua_newtable(L); // create lua table for event
			// push items and set feilds
			lua_pushstring(L, "leaderboardImage");
			lua_setfield(L, -2, "type");
			lua_pushstring(L, [[leaderboard identifier] UTF8String]);
			lua_setfield(L, -2, "leaderboardID");
			
			size_t width = image.size.width;
			size_t height = image.size.height;
			ImageBitmap *imageBitmap = [[ImageBitmap alloc] init];
			unsigned char *bitmap = [imageBitmap extractRGBABitmapFromImage:image];
			if(bitmap != NULL) {
				// push bitmap to lua buffer image table
				if([self newLuaTableFromBitmap:bitmap width:width height:height luaState:L] == 1) {
					lua_setfield(L, -2, "image"); // add image table to event table
					// store reference to lua event table
					int luaTableRef = dmScript::Ref(L, LUA_REGISTRYINDEX);
					sendGameCenterCallbackLuaEvent(L, cbRef, selfRef, luaTableRef);
				} else {
					lua_settop(L, 0); // clear the whole stack
					const char *description = [[self stringAppendErrorDescription:@"Game Center image create dmBuffer error" 
					errorCode:GKErrorUnknown] UTF8String];
					sendGameCenterCallbackLuaErrorEvent(L, cbRef, selfRef, GKErrorUnknown, description);
				}
			} else {
				lua_settop(L, 0); // clear the whole stack
				const char *description = [[self stringAppendErrorDescription:@"Game Center image extract bitmap error" 
				errorCode:GKErrorUnknown] UTF8String];
				sendGameCenterCallbackLuaErrorEvent(L, cbRef, selfRef, GKErrorUnknown, description);
			}
			[imageBitmap release];
		}
	}];
}

- (void)sendImageFromLeaderboardSet:(GKLeaderboardSet *)leaderboardSet luaCallbackRef:(NSInteger)cbRef luaSelfRef:(NSInteger)selfRef luaState:(lua_State *)L
{
	// NSLog(@"DEBUG:NSLog [GameCenterDelegate.mm] sendImageFromLeaderboardSet leaderboardSet = %@", leaderboardSet);
#if defined(DM_PLATFORM_IOS)
	[leaderboardSet loadImageWithCompletionHandler:^(UIImage *image, NSError *error) {
#else // osx platform
	[leaderboardSet loadImageWithCompletionHandler:^(NSImage *image, NSError *error) {
#endif
		// NSLog(@"DEBUG:NSLog [GameCenterDelegate.mm] sendImageFromLeaderboardSet error = %@", error);
		// NSLog(@"DEBUG:NSLog [GameCenterDelegate.mm] sendImageFromLeaderboardSet image = %@", image);
		if(error) {
			const char *description = [[self stringAppendErrorDescription:[error localizedDescription]
				errorCode:[error code]] UTF8String];
			sendGameCenterCallbackLuaErrorEvent(L, cbRef, selfRef, [error code], description);
		} else if(error == nil && image == nil) {
			const char *description = [[self stringAppendErrorDescription:@"Game Center LeaderboardSet has no image" 
				errorCode:GKErrorInvalidParameter] UTF8String];
			sendGameCenterCallbackLuaErrorEvent(L, cbRef, selfRef, GKErrorInvalidParameter, description);
		} else {
			lua_newtable(L); // create lua table for event
			// push items and set feilds
			lua_pushstring(L, "leaderboardSetImage");
			lua_setfield(L, -2, "type");
			lua_pushstring(L, [[leaderboardSet identifier] UTF8String]);
			lua_setfield(L, -2, "leaderboardSetID");
			
			size_t width = image.size.width;
			size_t height = image.size.height;
			ImageBitmap *imageBitmap = [[ImageBitmap alloc] init];
			unsigned char *bitmap = [imageBitmap extractRGBABitmapFromImage:image];
			if(bitmap != NULL) {
				// push bitmap to lua buffer image table
				if([self newLuaTableFromBitmap:bitmap width:width height:height luaState:L] == 1) {
					lua_setfield(L, -2, "image"); // add image table to event table
					// store reference to lua event table
					int luaTableRef = dmScript::Ref(L, LUA_REGISTRYINDEX);
					sendGameCenterCallbackLuaEvent(L, cbRef, selfRef, luaTableRef);
				} else {
					lua_settop(L, 0); // clear the whole stack
					const char *description = [[self stringAppendErrorDescription:@"Game Center image create dmBuffer error" 
					errorCode:GKErrorUnknown] UTF8String];
					sendGameCenterCallbackLuaErrorEvent(L, cbRef, selfRef, GKErrorUnknown, description);
				}
			} else {
				lua_settop(L, 0); // clear the whole stack
				const char *description = [[self stringAppendErrorDescription:@"Game Center image extract bitmap error" 
				errorCode:GKErrorUnknown] UTF8String];
				sendGameCenterCallbackLuaErrorEvent(L, cbRef, selfRef, GKErrorUnknown, description);
			}
			[imageBitmap release];
		}
	}];
}

- (void)sendImageFromAchievementDescription:(GKAchievementDescription *)achvDescription luaCallbackRef:(NSInteger)cbRef luaSelfRef:(NSInteger)selfRef luaState:(lua_State *)L
{
#if defined(DM_PLATFORM_IOS)
	[achvDescription loadImageWithCompletionHandler:^(UIImage *image, NSError *error) {
#else // osx platform
	[achvDescription loadImageWithCompletionHandler:^(NSImage *image, NSError *error) {
#endif
		//NSLog(@"DEBUG:NSLog [GameCenterDelegate.mm] sendImageFromAchievementDescription error = %@", error);
		//NSLog(@"DEBUG:NSLog [GameCenterDelegate.mm] sendImageFromAchievementDescription image = %@", image);
		if (error) {
			const char *description = [[self stringAppendErrorDescription:[error localizedDescription]
				errorCode:[error code]] UTF8String];
			sendGameCenterCallbackLuaErrorEvent(L, cbRef, selfRef, [error code], description);
		} else if(error == nil && image == nil) {
			const char *description = [[self stringAppendErrorDescription:@"Game Center Achievement has no image" 
				errorCode:GKErrorInvalidParameter] UTF8String];
			sendGameCenterCallbackLuaErrorEvent(L, cbRef, selfRef, GKErrorInvalidParameter, description);
		} else {
			lua_newtable(L); // create lua table for event
			// push items and set feilds
			lua_pushstring(L, "achievementImage");
			lua_setfield(L, -2, "type");
			lua_pushstring(L, [[achvDescription identifier] UTF8String]);
			lua_setfield(L, -2, "achievementID");

			size_t width = image.size.width;
			size_t height = image.size.height;
			ImageBitmap *imageBitmap = [[ImageBitmap alloc] init];
			unsigned char *bitmap = [imageBitmap extractRGBABitmapFromImage:image];
			if(bitmap != NULL) {
				// push bitmap to lua buffer image table
				if([self newLuaTableFromBitmap:bitmap width:width height:height luaState:L] == 1) {
					lua_setfield(L, -2, "image"); // add image table to event table
					// store reference to lua event table
					int luaTableRef = dmScript::Ref(L, LUA_REGISTRYINDEX);
					sendGameCenterCallbackLuaEvent(L, cbRef, selfRef, luaTableRef);
				} else {
					lua_settop(L, 0); // clear the whole stack
					const char *description = [[self stringAppendErrorDescription:@"Game Center image create dmBuffer error" 
					errorCode:GKErrorUnknown] UTF8String];
					sendGameCenterCallbackLuaErrorEvent(L, cbRef, selfRef, GKErrorUnknown, description);
				}
			} else {
				lua_settop(L, 0); // clear the whole stack
				const char *description = [[self stringAppendErrorDescription:@"Game Center image extract bitmap error" 
				errorCode:GKErrorUnknown] UTF8String];
				sendGameCenterCallbackLuaErrorEvent(L, cbRef, selfRef, GKErrorUnknown, description);
			}
			[imageBitmap release];
		}
	}];
}

@end