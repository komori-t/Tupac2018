#include "ServoConverter.h"

void ServoConverter_convert(GamepadStickAxis axis, int value)
{
    switch (axis) {
        case LeftStickX:
            ServoConverter_setServoSpeed(Servo0, value * INT8_MAX / INT16_MAX);
            break;
            
        default:
            break;
    }
}
