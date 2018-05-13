#import "GamepadController.h"
#import "WiredXBoxController.h"
#import "WirelessXBoxController.h"

static const unsigned int RightStick = 1;
static const unsigned int LRTrigger  = 2;

static const unsigned int RightX = 0;
static const unsigned int RightY = 1;
static const unsigned int LTriggerAxis = 0;
static const unsigned int RTriggerAxis = 1;

const static GamepadStickAxis ButtonTable[] = {
    AButton,
    BButton,
    XButton,
    YButton,
    LeftTriggerButton,
    RightTriggerButton,
    LeftStickButton,
    RightStickButton,
    StartButton,
    SelectButton,
    XBoxButton,
};

static const int stickThreshold = 5000;

@implementation GamepadController
{
    DDHidJoystick *gamepad;
}

+ (instancetype)controller
{
    NSArray *gamepads = [DDHidJoystick allJoysticks];
    if ([gamepads count]) {
        DDHidJoystick *gamepad = [gamepads firstObject];
        if ([gamepad.productName isEqualToString:@"Xbox One Wired Controller"]) {
            return [[WiredXBoxController alloc] initWithJoystick:gamepad];
        } else if ([gamepad.productName isEqualToString:@"Xbox Wireless Controller"]) {
            return [[WirelessXBoxController alloc] initWithJoystick:gamepad];
        } else {
            return [[GamepadController alloc] initWithJoystick:gamepad];
        }
    }
    return nil;
}

- (instancetype)init
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (instancetype)initWithJoystick:(DDHidJoystick *)joystick
{
    if (self = [super init]) {
        gamepad = joystick;
        [gamepad setDelegate: self];
        [gamepad startListening];
    }
    return self;
}

- (void)ddhidJoystick:(DDHidJoystick *)joystick buttonUp:(unsigned int)buttonNumber
{
    if (buttonNumber >= 11) {
        [self.delegate gamepad:self updateValue:-1 forStickAxis:Pov];
    } else {
        [self.delegate gamepad:self updateValue:0 forStickAxis:ButtonTable[buttonNumber]];
    }
}

- (void)ddhidJoystick:(DDHidJoystick *)joystick buttonDown:(unsigned int)buttonNumber
{
    switch (buttonNumber) {
        case 11:
            [self.delegate gamepad:self updateValue:0 forStickAxis:Pov];
            break;
            
        case 12:
            [self.delegate gamepad:self updateValue:18000 forStickAxis:Pov];
            break;
            
        case 13:
            [self.delegate gamepad:self updateValue:27000 forStickAxis:Pov];
            break;
            
        case 14:
            [self.delegate gamepad:self updateValue:9000 forStickAxis:Pov];
            break;
            
        default:
            [self.delegate gamepad:self updateValue:1 forStickAxis:ButtonTable[buttonNumber]];
            break;
    }
}

- (void)ddhidJoystick:(DDHidJoystick *)joystick stick:(unsigned int)stick xChanged:(int)value
{
    if (abs(value) < stickThreshold) {
        value = 0;
    }
    [self.delegate gamepad:self updateValue:value forStickAxis:LeftStickX];
}

- (void)ddhidJoystick:(DDHidJoystick *)joystick stick:(unsigned int)stick yChanged:(int)value
{
    if (abs(value) < stickThreshold) {
        value = 0;
    }
    [self.delegate gamepad:self updateValue:-value forStickAxis:LeftStickY];
}

- (void)ddhidJoystick:(DDHidJoystick *)joystick stick:(unsigned int)stick
            otherAxis:(unsigned int)otherAxis valueChanged:(int)value
{
    switch (stick) {
        case RightStick:
            if (abs(value) < stickThreshold) {
                value = 0;
            }
            switch (otherAxis) {
                case RightX:
                    [self.delegate gamepad:self updateValue:value forStickAxis:RightStickX];
                    break;
                    
                case RightY:
                    [self.delegate gamepad:self updateValue:-value forStickAxis:RightStickY];
                    break;
                    
                default:
                    break;
            }
            break;
            
        case LRTrigger:
            switch (otherAxis) {
                case LTriggerAxis:
                    [self.delegate gamepad:self updateValue:value forStickAxis:LeftTrigger];
                    break;
                    
                case RTriggerAxis:
                    [self.delegate gamepad:self updateValue:value forStickAxis:RightTrigger];
                    break;
                    
                default:
                    break;
            }
            break;
            
        default:
            break;
    }
}

- (void)ddhidJoystick:(DDHidJoystick *)joystick
                stick:(unsigned int)stick povNumber:(unsigned int)povNumber valueChanged:(int)value
{
    [self.delegate gamepad:self updateValue:value forStickAxis:Pov];
}

@end
