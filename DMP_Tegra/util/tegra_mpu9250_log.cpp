#include "tegra_mpu9250_log.h"

// Based on log_stm32.c from Invensense motion_driver_6.12

#define BUF_SIZE        (256)
#define PACKET_LENGTH   (23)

#define PACKET_DEBUG    (1)
#define PACKET_QUAT     (2)
#define PACKET_DATA     (3)

void logString(char * string) 
{
}

int _MLPrintLog (int priority, const char* tag, const char* fmt, ...)
{
}

void eMPL_send_quat(long *quat)
{
}

void eMPL_send_data(unsigned char type, long *data)
{
}
