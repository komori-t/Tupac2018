#include "serial.h"
#include <stdio.h>
#include <unistd.h>
#include <sys/signal.h>

static void *readingThread(void *arg)
{
    serial_t *self = arg;
    uint8_t buf[8];
    while (1) {
        ssize_t ret = read(self->fd, buf, 8);
        if (ret > 0) {
            self->handler(buf, ret);
        }
    }
    return NULL;
}

void serial_init(serial_t *self, const char *device, speed_t baud, serial_handler_t handler)
{
    int             fileDescriptor = -1;
    int             handshake;
    struct termios  options;
    
    fileDescriptor = open(device, O_RDWR | O_NOCTTY | O_NONBLOCK);
    if (fileDescriptor == -1) {
        perror("open");
    }

    self->handler = handler;
    pthread_create(&self->thread, NULL, readingThread, self);
    
    if (ioctl(fileDescriptor, TIOCEXCL) == -1) {
        perror("ioctl");
    }
    
    if (fcntl(fileDescriptor, F_SETFL, 0) == -1) {
        perror("fcntl");
    }
    
    if (tcgetattr(fileDescriptor, &self->gOriginalTTYAttrs) == -1) {
        perror("tcgetattr");
    }
    
    options = self->gOriginalTTYAttrs;
    
    cfmakeraw(&options);
    options.c_cc[VMIN]  = 0;
    options.c_cc[VTIME] = 10;
    
    // The baud rate, word length, and handshake options can be set as follows:
    cfsetspeed(&options, baud);      // Set the baud
    /*options.c_cflag |= (CS8     |    // Use 8 bit words
                        PARENB  |    // Parity enable (even parity if PARODD not also set)
                        CRTSCTS);    // Flow control*/

    // Cause the new options to take effect immediately.
    if (tcsetattr(fileDescriptor, TCSANOW, &options) == -1) {
        perror("tcsetattr");
    }
    
    // Set the modem lines depending on the bits set in handshake
    handshake = TIOCM_DTR | TIOCM_RTS | TIOCM_CTS | TIOCM_DSR;
    if (ioctl(fileDescriptor, TIOCMSET, &handshake) == -1) {
        perror("ioctl");
    }
    
    // Store the state of the modem lines in handshake
    if (ioctl(fileDescriptor, TIOCMGET, &handshake) == -1) {
        perror("ioctl");
    }
    
    self->fd = fileDescriptor;
}

void serial_write(serial_t *self, const uint8_t *data, size_t count)
{
    write(self->fd, data, count);
}

