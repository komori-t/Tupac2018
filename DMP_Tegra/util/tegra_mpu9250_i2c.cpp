#include "tegra_mpu9250_i2c.h"
#include "I2C.hpp"
#include <cstring>

static I2C i2c("/dev/i2c-1");

int tegra_i2c_write(unsigned char slave_addr, unsigned char reg_addr,
                       unsigned char length, unsigned char * data)
{
	unsigned char buf[length + 1];
	buf[0] = reg_addr;
	memcpy(&buf[1], data, length);
	return i2c.write(slave_addr, reinterpret_cast<char *>(buf), length + 1);
}

int tegra_i2c_read(unsigned char slave_addr, unsigned char reg_addr,
                       unsigned char length, unsigned char * data)
{
	i2c.write(slave_addr, reinterpret_cast<char *>(&reg_addr), 1, true);
	return i2c.read(slave_addr, reinterpret_cast<char *>(data), length);
}
