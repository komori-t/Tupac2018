#ifndef __DigitalIn__
#define __DigitalIn__

#include "DigitalPin.hpp"
#include "SysfsGPIO.hpp"

class DigitalIn : public DigitalPin {
protected:
    SysfsGPIO value;

public:
    DigitalIn(uint8_t pin) : DigitalPin(pin, "in"), value(pin, "value", O_RDONLY) {
    }
    int read() {
        uint8_t ret;
        value.pread(&ret, 1);
        return ret != '0';
    }
    operator int() {
        return read();
    }
};

#endif
