// Apple GameKit Defold Extension
// ShowCommands.h

#import "GameCenterDelegate.h"

@interface ShowCommands : NSObject

- (instancetype)initWithGameCenterDelegate:(GameCenterDelegate *)delegate;

- (void)gcShowCommandFromLuaState:(lua_State *)L;

@end