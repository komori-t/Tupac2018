#include "Serial.hpp"
#include <fcntl.h>
#include <stddef.h>

Serial::Serial(const char *dev, speed_t baud, bool &success)
{
    success = false;
    if (! dev) {
        return;
    }
    
    fd = open(dev, O_RDWR | O_NOCTTY);
    if (fd == -1) {
        perror("open");
        return;
    }
    
    if (ioctl(fd, TIOCEXCL) == -1) {
        perror("ioctl");
        return;
    }
    
    if (fcntl(fd, F_SETFL, 0) == -1) {
        perror("fcntl");
        return;
    }
    
    if (tcgetattr(fd, &options) == -1) {
        perror("tcgetattr");
        return;
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
        return;
    }
    
    // Set the modem lines depending on the bits set in handshake
    int handshake = TIOCM_DTR | TIOCM_RTS | TIOCM_CTS | TIOCM_DSR;
    if (ioctl(fd, TIOCMSET, &handshake) == -1) {
        perror("ioctl");
        return;
    }
    
    // Store the state of the modem lines in handshake
    if (ioctl(fd, TIOCMGET, &handshake) == -1) {
        perror("ioctl");
        return;
    }
    
    success = true;
}

bool Serial::changeBaud(speed_t baud)
{
    cfsetspeed(&options, baud);
    if (tcsetattr(fd, TCSANOW, &options) == -1) {
        perror("tcsetattr");
        return false;
    }
    return true;
}

Serial::~Serial()
{
    if (fd >= 0) {
        close(fd);
    }
}
