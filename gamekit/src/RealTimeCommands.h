// Apple GameKit Defold Extension
// RealTimeCommands.h

#import "GameCenterDelegate.h"

@interface RealTimeCommands : NSObject

- (instancetype)initWithGameCenterDelegate:(GameCenterDelegate *)delegate;

- (void)gcRealTimeCommandFromLuaState:(lua_State *)L;

@end