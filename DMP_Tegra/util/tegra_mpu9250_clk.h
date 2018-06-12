#ifndef _TEGRA_MPU9250_CLK_H_
#define _TEGRA_MPU9250_CLK_H_

#if defined(__cplusplus) 
extern "C" {
#endif

int tegra_get_clock_ms(unsigned long *count);
int tegra_delay_ms(unsigned long num_ms);

#if defined(__cplusplus) 
}
#endif

#endif // _TEGRA_MPU9250_CLK_H_
