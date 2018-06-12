#include "tegra_mpu9250_clk.h"
#include <unistd.h>
#include <chrono>

static auto LaunchTime = std::chrono::system_clock::now();

int tegra_get_clock_ms(unsigned long *count)
{
    auto duration = std::chrono::system_clock::now() - LaunchTime;
	*count = std::chrono::duration_cast<std::chrono::milliseconds>(duration).count();
	return 0;
}

int tegra_delay_ms(unsigned long num_ms)
{
	usleep(num_ms * 1000);
	return 0;
}
