#ifndef __Servo__
#define __Servo__

/* The classes below are exported */
#pragma GCC visibility push(default)

#include <cstdint>
#include "Serial.hpp"

template <uint8_t id>
class Servo
{
protected:
    Serial *serial;
    Servo(Serial *_serial) : serial(_serial) {};
public:
    virtual void setTorque(bool enable, bool *success = nullptr) = 0;
    virtual void setPosition(double position, bool *success = nullptr) = 0;
    virtual double position(bool *success) = 0;
};

#pragma GCC visibility pop
#endif
