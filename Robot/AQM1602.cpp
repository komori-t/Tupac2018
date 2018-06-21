#include "AQM1602.h"
#include <unistd.h>

const uint8_t AQM1602::Address = 0x7C;

static void wait_us(int us)
{
    usleep(us + 1000);
}

static void wait_ms(int ms)
{
    wait_us(ms * 1000);
}

AQM1602::AQM1602(const char *dev) : i2c(dev)
{
    wait_ms(50);
    writeInstruction(0x38);
    writeInstruction(0x39);
    writeInstruction(0x14);
    writeInstruction(0x70);
    writeInstruction(0x56);
    writeInstruction(0x6C);
    wait_ms(210);
    writeInstruction(0x38);
    writeInstruction(0x0C);
    clear();
}

void AQM1602::writeInstruction(uint8_t value)
{
    char cmd[2] = {0, value};
    i2c.write(AQM1602::Address, cmd, 2);
    wait_us(50);
}

void AQM1602::clear()
{
    writeInstruction(0x01);
    wait_ms(2);
}

void AQM1602::print(const char *txt)
{
    writeInstruction(0b10000000);
    char cmd[2] = {0x40, 0};
    while (*txt != '\0') {
        cmd[1] = *txt;
        i2c.write(AQM1602::Address, cmd, 2);
        ++txt;
    }
}
