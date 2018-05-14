#import <Foundation/Foundation.h>
#import "DDHidJoystick.h"
#import "GamepadConstants.h"

@class GamepadController;

@protocol GamepadDelegate <NSObject>

- (void)gamepad:(GamepadController *)gamepad updateValue:(int)value forStickAxis:(GamepadStickAxis)stick;

@end

@interface GamepadController : NSObject <DDHidJoystickDelegate>

@property id<GamepadDelegate> delegate;

+ (instancetype)controller;
- (instancetype)initWithJoystick:(DDHidJoystick *)joystick;

@end
