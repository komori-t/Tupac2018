#include "Serial.hpp"
#include <fcntl.h>
#include <stddef.h>

Serial::Serial(const char *dev, speed_t baud)
{
    pthread_mutex_init(&mutex, NULL);
    
    int handshake;
    
    fd = open(dev, O_RDWR | O_NOCTTY | O_NONBLOCK);
    if (fd == -1) {
        perror("open");
    }
    
    if (ioctl(fd, TIOCEXCL) == -1) {
        perror("ioctl");
    }
    
    if (fcntl(fd, F_SETFL, 0) == -1) {
        perror("fcntl");
    }
    
    if (tcgetattr(fd, &options) == -1) {
        perror("tcgetattr");
    }
    
    cfmakeraw(&options);
    options.c_cc[VMIN]  = 0;
    options.c_cc[VTIME] = 10;
    
    // The baud rate, word length, and handshake options can be set as follows:
    cfsetspeed(&options, baud);      // Set the baud
    /*options.c_cflag |= (CS8     |    // Use 8 bit words
     PARENB  |    // Parity enable (even parity if PARODD not also set)
     CRTSCTS);    // Flow control*/
    
    // Cause the new options to take effect immediately.
    if (tcsetattr(fd, TCSANOW, &options) == -1) {
        perror("tcsetattr");
    }
    
    // Set the modem lines depending on the bits set in handshake
    handshake = TIOCM_DTR | TIOCM_RTS | TIOCM_CTS | TIOCM_DSR;
    if (ioctl(fd, TIOCMSET, &handshake) == -1) {
        perror("ioctl");
    }
    
    // Store the state of the modem lines in handshake
    if (ioctl(fd, TIOCMGET, &handshake) == -1) {
        perror("ioctl");
    }
}

void Serial::changeBaud(speed_t baud)
{
    cfsetspeed(&options, baud);
    if (tcsetattr(fd, TCSANOW, &options) == -1) {
        perror("tcsetattr");
    }
}

Serial::~Serial()
{
    pthread_mutex_destroy(&mutex);
    close(fd);
}
