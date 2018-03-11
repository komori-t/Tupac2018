#ifndef __DynamixelServo__
#define __DynamixelServo__

#include "SerialController.hpp"

class Servo {
    SerialController *serial;
    uint8_t id;
    
public:
    Servo(SerialController *serial, uint8_t id);
    bool setGoalPosition(int32_t position);
};

#endif
