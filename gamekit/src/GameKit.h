// Apple GameKit Defold Extension
// GameKit.h

// use #import for GameKit.h header as include guard

#include <dmsdk/sdk.h>

void finalizeGameKit(lua_State *L);
void gameCenterSignIn(lua_State *L);
void gameCenterShowSignInUI(lua_State *L);
void gameCenterSendCommand(lua_State *L);
void gameCenterGetCommand(lua_State *L);
void gameCenterShowCommand(lua_State *L);
