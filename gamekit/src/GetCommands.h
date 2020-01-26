// Apple GameKit Defold Extension
// GetCommands.h

#import "GameCenterDelegate.h"

@interface GetCommands : NSObject

- (instancetype)initWithGameCenterDelegate:(GameCenterDelegate *)delegate;

- (void)gcGetCommandFromLuaState:(lua_State *)L;

@end