#ifndef __serial__
#define __serial__

#include <stdint.h>
#include <termios.h>
#include <fcntl.h>
#include <sys/ioctl.h>
#include <stddef.h>
#include <pthread.h>

typedef void (*serial_handler_t)(uint8_t *data, size_t count);

typedef struct {
    int fd;
    struct termios gOriginalTTYAttrs;
    serial_handler_t handler;
    pthread_t thread;
} serial_t;

void serial_init(serial_t *self, const char *device, speed_t baud, serial_handler_t handler);
void serial_write(serial_t *self, const uint8_t *data, size_t count);

#endif

