#ifndef __DigitalPin
#define __DigitalPin

#include "SysfsGPIO.hpp"
#include <string.h>

class DigitalPin
{
    char pinStr[4];

public:
    DigitalPin(uint8_t pin, const char *mode) {
        SysfsGPIO exporter("/sys/class/gpio/export", O_WRONLY);
        snprintf(pinStr, sizeof(pinStr), "%u", pin);
        exporter.pwrite(pinStr, 4);
        char dirPath[] = "/sys/class/gpio/gpio187/direction";
        snprintf(dirPath, sizeof(dirPath), "/sys/class/gpio/gpio%u/direction", pin);
        SysfsGPIO direction(dirPath, O_WRONLY);
        direction.pwrite(mode, strlen(mode));
    }
    ~DigitalPin() {
        SysfsGPIO unexporter("/sys/class/gpio/unexport", O_WRONLY);
        unexporter.pwrite(pinStr, 4);
    }
};

#endif
