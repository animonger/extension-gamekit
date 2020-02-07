// Apple GameKit Defold Extension
// LuaEvents.cpp

#include <stdio.h>
#include <dmsdk/sdk.h>
#include "LuaEvents.h"
// #include "LuaStackDump.h"

// 0 = GC_SIGN_IN_CALLBACK, 1 = GC_SIGN_IN_LUA_INSTANCE, 2 = GC_RT_MATCHMAKER_CALLBACK, 3 = GC_RT_MATCHMAKER_LUA_INSTANCE
static int luaRefs[] = {LUA_NOREF, LUA_NOREF, LUA_NOREF, LUA_NOREF, LUA_NOREF, LUA_NOREF};

bool registerGameCenterCallbackLuaRef(lua_State *L, LuaRefKey cbKey, LuaRefKey selfKey)
{
	// dmLogUserDebug(">LuaEvents.cpp< registerGameCenterCallbackLuaRef called");
	luaL_checktype(L, -1, LUA_TFUNCTION);
	if(luaRefs[cbKey] == LUA_NOREF) {
		// printLuaStack(L);
		// store reference to lua callback function
		luaRefs[cbKey] = dmScript::Ref(L, LUA_REGISTRYINDEX);
		// dmLogUserDebug(">LuaEvents.cpp< callback luaRefs[%i] = %i", cbKey, luaRefs[cbKey]);
		// store reference to lua self (the script instance)
		dmScript::GetInstance(L);
		luaRefs[selfKey] = dmScript::Ref(L, LUA_REGISTRYINDEX);
		// dmLogUserDebug(">LuaEvents.cpp< self instance luaRefs[%i] = %i", selfKey, luaRefs[selfKey]);
	}
	// printLuaStack(L);
	return luaRefs[cbKey] != LUA_NOREF ? true : false;
}

void unRegisterGameCenterCallbackLuaRef(lua_State *L, LuaRefKey cbKey, LuaRefKey selfKey)
{
	// dmLogUserDebug(">LuaEvents.cpp< unRegisterGameCenterCallbackLuaRef called");
	if(luaRefs[cbKey] != LUA_NOREF) {
		dmScript::Unref(L, LUA_REGISTRYINDEX, luaRefs[cbKey]);
		dmScript::Unref(L, LUA_REGISTRYINDEX, luaRefs[selfKey]);
		luaRefs[cbKey] = LUA_NOREF;
		luaRefs[selfKey] = LUA_NOREF;
	}
}

void sendGameCenterRegisteredCallbackLuaEvent(lua_State *L, LuaRefKey cbKey, LuaRefKey selfKey, int luaTableRef)
{
	// dmLogUserDebug(">LuaEvents.cpp< sendGameCenterRegisteredCallbackLuaEvent called");
	if(luaRefs[cbKey] != LUA_NOREF) {
		// printLuaStack(L);
		// retrieve lua function
		lua_rawgeti(L, LUA_REGISTRYINDEX, luaRefs[cbKey]);
		// dmLogUserDebug(">LuaEvents.cpp< pushed gameCenterCallbackLuaRef to lua stack");
		// printLuaStack(L);
		// retrieve lua self (the script instance)
		lua_rawgeti(L, LUA_REGISTRYINDEX, luaRefs[selfKey]);
		lua_pushvalue(L, -1);
		dmScript::SetInstance(L);
		// dmLogUserDebug(">LuaEvents.cpp< pushed gameCenterSelfInstanceLuaRef to lua stack");
		// printLuaStack(L);
		// retrieve lua event table 
		lua_rawgeti(L, LUA_REGISTRYINDEX, luaTableRef);
		// dmLogUserDebug(">LuaEvents.cpp< pushed event luaTableRef = %i", luaTableRef);
		// printLuaStack(L);
		// call lua function with lua_pcall
		lua_pcall(L, 2, 0, 0);
		// dmLogUserDebug(">LuaEvents.cpp< lua_pcall(L, 2, 0, 0)");
		// unref luaTableRef from lua registry index
		dmScript::Unref(L, LUA_REGISTRYINDEX, luaTableRef);
		//dmLogUserDebug(">LuaEvents.cpp< unref luaTableRef from lua registry index");
	}
	else {
		dmLogError("You must register the lua callback function before you can send a lua callback event");
	}
	// printLuaStack(L);
}

void sendGameCenterRegisteredCallbackLuaErrorEvent(lua_State *L, LuaRefKey cbKey, LuaRefKey selfKey, int errorCode, const char *description)
{
	// dmLogUserDebug(">LuaEvents.cpp< sendGameCenterRegisteredCallbackLuaErrorEvent called");
	if(luaRefs[cbKey] != LUA_NOREF) {
		// printLuaStack(L);
		// retrieve lua function
		lua_rawgeti(L, LUA_REGISTRYINDEX, luaRefs[cbKey]);
		// dmLogUserDebug(">LuaEvents.cpp< pushed gameCenterCallbackLuaRef to lua stack");
		// printLuaStack(L);
		// retrieve lua self (the script instance)
		lua_rawgeti(L, LUA_REGISTRYINDEX, luaRefs[selfKey]);
		lua_pushvalue(L, -1);
		dmScript::SetInstance(L);
		// dmLogUserDebug(">LuaEvents.cpp< pushed gameCenterSelfInstanceLuaRef to lua stack");
		// printLuaStack(L);
		// create lua table for event
		lua_newtable(L);
		// dmLogUserDebug(">LuaEvents.cpp< new lua event table pushed to lua stack for error event");
		// printLuaStack(L);
		// push items and set feilds
		lua_pushstring(L, "error");
		lua_setfield(L, -2, "type");
		lua_pushinteger(L, errorCode);
		lua_setfield(L, -2, "errorCode");
		lua_pushstring(L, description);
		lua_setfield(L, -2, "description");
		// dmLogUserDebug(">LuaEvents.cpp< pushed items and field types to lua event table");
		// printLuaStack(L);
		// call lua function with lua_pcall
		lua_pcall(L, 2, 0, 0);
		// dmLogUserDebug(">LuaEvents.cpp< lua_pcall(L, 2, 0, 0)");
	}
	else {
		dmLogError("You must register the lua callback function before you can send a lua callback error event");
	}
	// printLuaStack(L);
}

int getTemporaryGameCenterCallbackLuaRef(lua_State *L)
{
	lua_getfield(L, -1, "callback");
	if(lua_type(L, -1) != LUA_TNIL) {
		luaL_checktype(L, -1, LUA_TFUNCTION);
		return dmScript::Ref(L, LUA_REGISTRYINDEX);
	} else {
		dmLogError("parameters table key 'callback' expected");
	}
	return LUA_NOREF; // invalid input for parameters table key
}

int getTemporaryGameCenterSelfLuaRef(lua_State *L)
{
    dmScript::GetInstance(L);
    luaL_checktype(L, -1, LUA_TUSERDATA);
    return dmScript::Ref(L, LUA_REGISTRYINDEX);
}

void sendGameCenterCallbackLuaEvent(lua_State *L, int luaCallbackRef, int luaSelfRef, int luaTableRef)
{
	// dmLogUserDebug(">LuaEvents.cpp< sendGameCenterCallbackLuaEvent called");
	// retrieve lua function
	lua_rawgeti(L, LUA_REGISTRYINDEX, luaCallbackRef);
	// dmLogUserDebug(">LuaEvents.cpp< pushed luaCallbackRef to lua stack");
	// printLuaStack(L);
	// retrieve lua self (the script instance)
	lua_rawgeti(L, LUA_REGISTRYINDEX, luaSelfRef);
	lua_pushvalue(L, -1);
	dmScript::SetInstance(L);
	// dmLogUserDebug(">LuaEvents.cpp< pushed luaSelfRef to lua stack");
	// printLuaStack(L);
	// retrieve lua event table 
	lua_rawgeti(L, LUA_REGISTRYINDEX, luaTableRef);
	// dmLogUserDebug(">LuaEvents.cpp< pushed event luaTableRef to lua stack");
	// printLuaStack(L);
	// call lua function with lua_pcall
	lua_pcall(L, 2, 0, 0);
	// dmLogUserDebug(">LuaEvents.cpp< lua_pcall(L, 2, 0, 0)");
	// printLuaStack(L);
	// unref lua references from lua registry index
	dmScript::Unref(L, LUA_REGISTRYINDEX, luaCallbackRef);
	dmScript::Unref(L, LUA_REGISTRYINDEX, luaSelfRef);
	dmScript::Unref(L, LUA_REGISTRYINDEX, luaTableRef);
	// dmLogUserDebug(">LuaEvents.cpp< unref luaCallbackRef, luaSelfRef, luaTableRef from lua registry index");
}

void sendGameCenterCallbackLuaErrorEvent(lua_State *L, int luaCallbackRef, int luaSelfRef, int errorCode, const char *description)
{
	// dmLogUserDebug(">LuaEvents.cpp< sendGameCenterCallbackLuaErrorEvent called");
	// retrieve lua function
	lua_rawgeti(L, LUA_REGISTRYINDEX, luaCallbackRef);
	// dmLogUserDebug(">LuaEvents.cpp< pushed luaCallbackRef to lua stack");
	// printLuaStack(L);
	// retrieve lua self (the script instance)
	lua_rawgeti(L, LUA_REGISTRYINDEX, luaSelfRef);
	lua_pushvalue(L, -1);
	dmScript::SetInstance(L);
	// dmLogUserDebug(">LuaEvents.cpp< pushed luaSelfRef to lua stack");
	// printLuaStack(L);
	// create lua table for event
	lua_newtable(L);
	// dmLogUserDebug(">LuaEvents.cpp< new lua event table pushed to lua stack for error event");
	// printLuaStack(L);
	// push items and set feilds
	lua_pushstring(L, "error");
	lua_setfield(L, -2, "type");
	lua_pushinteger(L, errorCode);
	lua_setfield(L, -2, "errorCode");
	lua_pushstring(L, description);
	lua_setfield(L, -2, "description");
	// dmLogUserDebug(">LuaEvents.cpp< pushed items and field types to lua event table");
	// printLuaStack(L);
	// call lua function with lua_pcall
	lua_pcall(L, 2, 0, 0);
	// dmLogUserDebug(">LuaEvents.cpp< lua_pcall(L, 2, 0, 0)");
	// printLuaStack(L);
	dmScript::Unref(L, LUA_REGISTRYINDEX, luaCallbackRef);
	dmScript::Unref(L, LUA_REGISTRYINDEX, luaSelfRef);
	// dmLogUserDebug(">LuaEvents.cpp< unref luaCallbackRef and luaSelfRef from lua registry index");
}

void sendGameCenterCallbackLuaSuccessEvent(lua_State *L, int luaCallbackRef, int luaSelfRef, const char *description)
{
	// dmLogUserDebug(">LuaEvents.cpp< sendGameCenterCallbackLuaSuccessEvent called");
	// retrieve lua function
	lua_rawgeti(L, LUA_REGISTRYINDEX, luaCallbackRef);
	// dmLogUserDebug(">LuaEvents.cpp< pushed luaCallbackRef to lua stack");
	// printLuaStack(L);
	// retrieve lua self (the script instance)
	lua_rawgeti(L, LUA_REGISTRYINDEX, luaSelfRef);
	lua_pushvalue(L, -1);
	dmScript::SetInstance(L);
	// dmLogUserDebug(">LuaEvents.cpp< pushed luaSelfRef to lua stack");
	// printLuaStack(L);
	// create lua table for event
	lua_newtable(L);
	// dmLogUserDebug(">LuaEvents.cpp< new lua event table pushed to lua stack for error event");
	// printLuaStack(L);
	// push items and set feilds
	lua_pushstring(L, "success");
	lua_setfield(L, -2, "type");
	lua_pushstring(L, description);
	lua_setfield(L, -2, "description");
	// dmLogUserDebug(">LuaEvents.cpp< pushed items and field types to lua event table");
	// printLuaStack(L);
	// call lua function with lua_pcall
	lua_pcall(L, 2, 0, 0);
	// dmLogUserDebug(">LuaEvents.cpp< lua_pcall(L, 2, 0, 0)");
	// printLuaStack(L);
	dmScript::Unref(L, LUA_REGISTRYINDEX, luaCallbackRef);
	dmScript::Unref(L, LUA_REGISTRYINDEX, luaSelfRef);
	// dmLogUserDebug(">LuaEvents.cpp< unref luaCallbackRef and luaSelfRef from lua registry index");
}
