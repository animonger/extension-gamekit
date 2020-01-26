// Lua helper for debugging only
// LuaStackDump.cpp

#include "LuaStackDump.h"

void printLuaStack( lua_State *L )
{
	int i;
	int top = lua_gettop(L);
	dmLogUserDebug(""); // switched from printf logging to dmLogUserDebug because printf isn't logging to osx/xcode console
	dmLogUserDebug("--- > Lua Stack length = %i", top);

	for (i = top; i >= 1; i--) {  // repeat for each level
		int t = lua_type(L, i);
		switch (t) {
			case LUA_TSTRING:
			dmLogUserDebug("--- lua stack index: %i = %s (string)", i, lua_tostring(L, i));
			break;

			case LUA_TNUMBER:
			dmLogUserDebug("--- lua stack index: %i = %g (number)", i, lua_tonumber(L, i));
			break;
			
			case LUA_TBOOLEAN:
			dmLogUserDebug("--- lua stack index: %i = %s (boolean)", i, lua_toboolean(L, i) ? "true" : "false");
			break;

			case LUA_TFUNCTION:
			dmLogUserDebug("--- lua stack index: %i = %s", i, lua_typename(L, t));
			break;
			
			case LUA_TTABLE:
			dmLogUserDebug("--- lua stack index: %i = %s", i, lua_typename(L, t));
			break;

			case LUA_TNIL:
			dmLogUserDebug("--- lua stack index: %i = %s", i, lua_typename(L, t));
			break;

			case LUA_TUSERDATA:
			dmLogUserDebug("--- lua stack index: %i = %s", i, lua_typename(L, t));
			break;

			default:  // other lua types: LUA_TNONE, LUA_TTHREAD, LUA_TLIGHTUSERDATA 
			dmLogUserDebug("--- lua stack index: %i = %s", i, lua_typename(L, t));
			break;
		}
		//printf("\n");
	}
	dmLogUserDebug("");
}
