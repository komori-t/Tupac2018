#ifndef _TEGRA_MPU9250_I2C_H_
#define _TEGRA_MPU9250_I2C_H_

#if defined(__cplusplus) 
extern "C" {
#endif

int tegra_i2c_write(unsigned char slave_addr, unsigned char reg_addr,
                       unsigned char length, unsigned char * data);
int tegra_i2c_read(unsigned char slave_addr, unsigned char reg_addr,
                       unsigned char length, unsigned char * data);

#if defined(__cplusplus) 
}
#endif

#endif // _TEGRA_MPU9250_I2C_H_
