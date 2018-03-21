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
    virtual void setTorque(bool enable, Serial::Error *error = nullptr) = 0;
    virtual void setPosition(double position, Serial::Error *error = nullptr) = 0;
    virtual double position(Serial::Error *error = nullptr) = 0;
    virtual void setID(uint8_t id, Serial::Error *error = nullptr) = 0;
    virtual void setBaud(speed_t baud, Serial::Error *error = nullptr) = 0;
};

#endif
