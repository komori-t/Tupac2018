#include "DynamixelServo.hpp"

Servo::Servo(SerialController *_serial, uint8_t _id) : serial(_serial), id(_id)
{
    
}

bool Servo::setGoalPosition(int32_t position)
{
    return serial->write(id, 116, position);
}
