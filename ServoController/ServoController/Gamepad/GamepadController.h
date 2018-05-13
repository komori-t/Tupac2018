#import <Foundation/Foundation.h>
#import "DDHidJoystick.h"

#define GAMEPAD_MAX DDHID_JOYSTICK_VALUE_MAX
#define GAMEPAD_MIN DDHID_JOYSTICK_VALUE_MIN

typedef enum {
    LeftStickX,
    LeftStickY,
    RightStickX,
    RightStickY,
    LeftTrigger,
    RightTrigger,
    LeftTriggerButton,
    RightTriggerButton,
    AButton,
    BButton,
    XButton,
    YButton,
    StartButton,
    SelectButton,
    XBoxButton,
    LeftStickButton,
    RightStickButton,
    Pov
} GamepadStickAxis;

@class GamepadController;

@protocol GamepadDelegate <NSObject>

- (void)gamepad:(GamepadController *)gamepad updateValue:(int)value forStickAxis:(GamepadStickAxis)stick;

@end

@interface GamepadController : NSObject <DDHidJoystickDelegate>

@property id<GamepadDelegate> delegate;

+ (instancetype)controller;
- (instancetype)initWithJoystick:(DDHidJoystick *)joystick;

@end
