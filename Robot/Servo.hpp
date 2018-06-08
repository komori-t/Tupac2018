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
    virtual void setTorque(bool enable, Serial::Error *error = nullptr) = 0;
    virtual void setPosition(double position, Serial::Error *error = nullptr) = 0;
    virtual double position(Serial::Error *error) = 0;
};

#pragma GCC visibility pop
#endif
