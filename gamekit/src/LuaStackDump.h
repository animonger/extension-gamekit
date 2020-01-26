// Lua helper for debugging only
// LuaStackDump.h

#ifndef LUASTACKDUMP_H_
#define LUASTACKDUMP_H_

#include <stdio.h>
#include <dmsdk/sdk.h>

void printLuaStack( lua_State *L );

#endif // LUASTACKDUMP_H_