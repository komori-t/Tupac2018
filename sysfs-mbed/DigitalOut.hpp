#ifndef __DigitalOut__
#define __DigitalOut__

#include "SysfsGPIO.hpp"
#include "DigitalPin.hpp"

class DigitalOut : public DigitalPin
{
    SysfsGPIO value;

public:
    DigitalOut(uint8_t pin) : DigitalPin(pin, "out"), value(pin, "value", O_WRONLY) {
    }
    void write(int aValue) {
        aValue = aValue ? '1' : '0';
        value.pwrite(&aValue, 1);
    }
    DigitalOut& operator = (int aValue) {
        write(aValue);
        return *this;
    }
    int read() {
        uint8_t ret;
        value.pread(&ret, 1);
        return ret;
    }
    operator int() {
        return read();
    }
};

#endif
