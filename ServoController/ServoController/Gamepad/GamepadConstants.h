#ifndef __GamepadStickAxis__
#define __GamepadStickAxis__

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

#endif
