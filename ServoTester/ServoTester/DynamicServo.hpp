#ifndef __DynamicServo__
#define __DynamicServo__

#include "Serial.hpp"

class DynamicServo
{
protected:
    Serial *serial;
    uint8_t id;
    DynamicServo(Serial *_serial, uint8_t _id) : serial(_serial), id(_id) {};
public:
    virtual void setTorque(bool enable, bool *success = nullptr) = 0;
    virtual void setPosition(double position, bool *success = nullptr) = 0;
    virtual double position(bool *success) = 0;
    virtual void setID(uint8_t id, bool *success) = 0;
    virtual void setBaud(speed_t baud, bool *sucess) = 0;
};

#endif
