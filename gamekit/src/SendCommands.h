// Apple GameKit Defold Extension
// SendCommands.h

#import "GameCenterDelegate.h"

@interface SendCommands : NSObject

- (instancetype)initWithGameCenterDelegate:(GameCenterDelegate *)delegate;

- (void)gcSendCommandFromLuaState:(lua_State *)L;

@end