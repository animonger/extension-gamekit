// Apple GameKit Defold Extension
// GameKit.cpp

#define EXTENSION_NAME GameKit
#define LIB_NAME "GameKit"
#define MODULE_NAME "gamekit"

// defold sdk
#define DLIB_LOG_DOMAIN "GameKit"
#include <dmsdk/sdk.h>

#include <stdlib.h>
#include <stdio.h>

#if defined(DM_PLATFORM_IOS) || defined(DM_PLATFORM_OSX)
#include <assert.h>
// #import GameKit.h to make sure its only included once
#import "GameKit.h"

static int GC_RealTime(lua_State *L)
{
	dmLogUserDebug(">GameKit.cpp< GC_RealTime called");
	gameCenterRealTimeCommand(L);
	return 0;
}

static int GC_Show(lua_State *L)
{
	// dmLogUserDebug(">GameKit.cpp< GC_Show called");
	gameCenterShowCommand(L);
	return 0;
}

static int GC_Get(lua_State *L)
{
	// dmLogUserDebug(">GameKit.cpp< GC_Get called");
	gameCenterGetCommand(L);
	return 0;
}

static int GC_Send(lua_State *L)
{
	// dmLogUserDebug(">GameKit.cpp< GC_Send called");
	gameCenterSendCommand(L);
	return 0;
}

static int GC_ShowSignInUI(lua_State *L)
{
	// dmLogUserDebug(">GameKit.cpp< GC_ShowSignInUI called");
	gameCenterShowSignInUI(L);
	return 0;
}

static int GC_SignIn(lua_State *L)
{
	// dmLogUserDebug(">GameKit.cpp< GC_SignIn called");
	gameCenterSignIn(L);
	return 0;
}

// Extension functions exposed to Lua
static const luaL_reg Module_methods[] =
{
	{"gc_signin", GC_SignIn},
	{"gc_show_signin", GC_ShowSignInUI},
	{"gc_send", GC_Send},
	{"gc_get", GC_Get},
	{"gc_show", GC_Show},
	{"gc_realtime", GC_RealTime},
	{0, 0}
};

static void LuaInit(lua_State *L)
{
	int top = lua_gettop(L);
	// Register lua fuction names
	luaL_register(L, MODULE_NAME, Module_methods);
	
	lua_pop(L, 1);
	assert(top == lua_gettop(L));
}
#endif

dmExtension::Result AppInitializeGameKit(dmExtension::AppParams* params)
{
	// dmLogUserDebug(">GameKit.cpp< AppInitializeGameKit called");
	return dmExtension::RESULT_OK;
}

dmExtension::Result AppFinalizeGameKit(dmExtension::AppParams* params)
{
	// dmLogUserDebug(">GameKit.cpp< AppFinalizeGameKit called");
	return dmExtension::RESULT_OK;
}

#if defined(DM_PLATFORM_IOS) || defined(DM_PLATFORM_OSX)
dmExtension::Result InitializeGameKit(dmExtension::Params* params)
{
	// Init Lua
	LuaInit(params->m_L);
	// dmLogUserDebug(">GameKit.cpp< Registered %s Extension", MODULE_NAME);
	return dmExtension::RESULT_OK;
}

dmExtension::Result FinalizeGameKit(dmExtension::Params* params)
{
	// dmLogUserDebug(">GameKit.cpp< FinalizeGameKit called");
	finalizeGameKit(params->m_L);
	return dmExtension::RESULT_OK;
}
#else // platform is Windows or Linux
dmExtension::Result InitializeGameKit(dmExtension::Params* params)
{
	dmLogError("GameKit extension only works with apple iOS and macOS.");
	return dmExtension::RESULT_OK;
}

dmExtension::Result FinalizeGameKit(dmExtension::Params* params)
{
	return dmExtension::RESULT_OK;
}
#endif

// Defold SDK uses a macro for setting up extension entry points:
// DM_DECLARE_EXTENSION(symbol, name, app_init, app_final, init, update, on_event, final)

DM_DECLARE_EXTENSION(EXTENSION_NAME, LIB_NAME, AppInitializeGameKit, AppFinalizeGameKit, InitializeGameKit, 0, 0, FinalizeGameKit)