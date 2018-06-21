#ifndef __AQM1602__
#define __AQM1602__

#include "I2C.hpp"

class AQM1602 {
    static const uint8_t Address;
    I2C i2c;
    void writeInstruction(uint8_t value);
public:
    AQM1602(const char *dev);
    void clear();
    void print(const char *txt);
};

#endif
