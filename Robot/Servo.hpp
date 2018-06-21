#ifndef __Servo__
#define __Servo__

/* The classes below are exported */
#pragma GCC visibility push(default)

#include <cstdint>
#include "Serial.hpp"

class Servo
{
protected:
    Serial *serial;
    Servo(Serial *_serial) : serial(_serial) {};
public:
    virtual void setTorque(bool enable, Serial::Error *error = nullptr) = 0;
    virtual void setPosition(double position, Serial::Error *error = nullptr) = 0;
    virtual double position(Serial::Error *error) = 0;
    virtual int32_t intPosition(Serial::Error *error) = 0;
    virtual void setPosition(int32_t position, Serial::Error *error) = 0;
    virtual void reboot(Serial::Error *error = nullptr) = 0;
    virtual void rebootIfNeeded(Serial::Error *error = nullptr) = 0;
    virtual uint16_t current(Serial::Error *error = nullptr) = 0;
};

#pragma GCC visibility pop
#endif
