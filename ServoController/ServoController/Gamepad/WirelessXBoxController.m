#import "WirelessXBoxController.h"

const static GamepadStickAxis ButtonTable[] = {
    AButton,
    BButton,
    -1,
    XButton,
    YButton,
    -1,
    LeftTriggerButton,
    RightTriggerButton,
    -1, -1, -1,
    StartButton,
    -1,
    LeftStickButton,
    RightStickButton,
    XBoxButton,
    SelectButton
};

@implementation WirelessXBoxController

- (instancetype)initWithJoystick:(DDHidJoystick *)joystick
{
    if (self = [super initWithJoystick:joystick]) {
        
    }
    return self;
}

- (void)ddhidJoystick:(DDHidJoystick *)joystick buttonUp:(unsigned int)buttonNumber
{
    [self.delegate gamepad:self updateValue:0 forStickAxis:ButtonTable[buttonNumber]];
}

- (void)ddhidJoystick:(DDHidJoystick *)joystick buttonDown:(unsigned int)buttonNumber
{
    [self.delegate gamepad:self updateValue:1 forStickAxis:ButtonTable[buttonNumber]];
}

@end
