// Apple GameKit Defold Extension
// LuaEvents.h

#ifndef LUAEVENTS_H_
#define LUAEVENTS_H_

#include <dmsdk/sdk.h>

enum LuaRefKey
{
	GC_SIGN_IN_CALLBACK,
	GC_SIGN_IN_LUA_INSTANCE
};

const char gkErrorCodes[32][46] = {
	"zero ",
	"GKErrorUnknown = 1 ",
	"GKErrorCancelled = 2 ",
	"GKErrorCommunicationsFailure = 3 ",
	"GKErrorUserDenied = 4 ",
	"GKErrorInvalidCredentials = 5 ",
	"GKErrorNotAuthenticated = 6 ",
	"GKErrorAuthenticationInProgress = 7 ",
	"GKErrorInvalidPlayer = 8 ",
	"GKErrorScoreNotSet = 9 ",
	"GKErrorParentalControlsBlocked = 10 ",
	"GKErrorPlayerStatusExceedsMaximumLength = 11 ",
	"GKErrorPlayerStatusInvalid = 12 ",
	"GKErrorMatchRequestInvalid = 13 ",
	"GKErrorUnderage = 14 ",
	"GKErrorGameUnrecognized = 15 ",
	"GKErrorNotSupported = 16 ",
	"GKErrorInvalidParameter = 17 ",
	"GKErrorUnexpectedConnection = 18 ",
	"GKErrorChallengeInvalid = 19 ",
	"GKErrorTurnBasedMatchDataTooLarge = 20 ",
	"GKErrorTurnBasedTooManySessions = 21 ",
	"GKErrorTurnBasedInvalidParticipant = 22 ",
	"GKErrorTurnBasedInvalidTurn = 23 ",
	"GKErrorTurnBasedInvalidState = 24 ",
	"GKErrorInvitationsDisabled = 25 ", // GKErrorOffline also equals 25 in older (2010) GKError.h files but it isn't listed in the curent apple docs
	"GKErrorPlayerPhotoFailure = 26 ",
	"GKErrorUbiquityContainerUnavailable = 27 ",
	"GKErrorMatchNotConnected = 28 ",
	"GKErrorGameSessionRequestInvalid = 29 ",
	"GKErrorRestrictedToAutomatch = 30 ",
	"GKErrorAPINotAvailable = 31 "
};

bool registerGameCenterCallbackLuaRef(lua_State *L, LuaRefKey cbKey, LuaRefKey selfKey);
void unRegisterGameCenterCallbackLuaRef(lua_State *L, LuaRefKey cbKey, LuaRefKey selfKey);
void sendGameCenterRegisteredCallbackLuaEvent(lua_State *L, LuaRefKey cbKey, LuaRefKey selfKey, int luaTableRef);
void sendGameCenterRegisteredCallbackLuaErrorEvent(lua_State *L, LuaRefKey cbKey, LuaRefKey selfKey, int errorCode, const char *description);
int getTemporaryGameCenterCallbackLuaRef(lua_State *L);
int getTemporaryGameCenterSelfLuaRef(lua_State *L);
void sendGameCenterCallbackLuaEvent(lua_State *L, int luaCallbackRef, int luaSelfRef, int luaTableRef);
void sendGameCenterCallbackLuaErrorEvent(lua_State *L, int luaCallbackRef, int luaSelfRef, int errorCode, const char *description);
void sendGameCenterCallbackLuaSuccessEvent(lua_State *L, int luaCallbackRef, int luaSelfRef, const char *description);

#endif // LUAEVENTS_H_