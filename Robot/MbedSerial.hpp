#ifndef __MbedSerial__
#define __MbedSerial__

#include <termios.h>
#include <unistd.h>
#include <sys/uio.h>
#include <sys/ioctl.h>
#include <array>
#include <fcntl.h>
#include <stddef.h>

namespace mbed {

class Serial
{
    int fd;
    termios options;

public:
    Serial(const char *dev) {
        fd = open(dev, O_RDWR | O_NOCTTY);
        if (fd < 0) {
            perror("open");
            return;
        }
        
        if (ioctl(fd, TIOCEXCL) < 0) {
            perror("ioctl");
            return;
        }
        
        if (fcntl(fd, F_SETFL, 0) < 0) {
            perror("fcntl");
            return;
        }
        
        if (tcgetattr(fd, &options) < 0) {
            perror("tcgetattr");
            return;
        }
        
        cfmakeraw(&options);
        options.c_cc[VMIN]  = 0;
        options.c_cc[VTIME] = 10;
        
        // The baud rate, word length, and handshake options can be set as follows:
        cfsetspeed(&options, B9600);      // Set the baud
        /*options.c_cflag |= (CS8     |    // Use 8 bit words
         PARENB  |    // Parity enable (even parity if PARODD not also set)
         CRTSCTS);    // Flow control*/
        
        // Cause the new options to take effect immediately.
        if (tcsetattr(fd, TCSANOW, &options) < 0) {
            perror("tcsetattr");
            return;
        }
        
        // Set the modem lines depending on the bits set in handshake
        int handshake = TIOCM_DTR | TIOCM_RTS | TIOCM_CTS | TIOCM_DSR;
        if (ioctl(fd, TIOCMSET, &handshake) < 0) {
            perror("ioctl");
            return;
        }
        
        // Store the state of the modem lines in handshake
        if (ioctl(fd, TIOCMGET, &handshake) < 0) {
            perror("ioctl");
            return;
        }
    }
    void baud(int baudrate) {
        cfsetspeed(&options, baudrate);
        if (tcsetattr(fd, TCSANOW, &options) < 0) perror("tcsetattr");
    }
    ssize_t write(const void *buffer, size_t length) {
        ssize_t ret = ::write(fd, buffer, length);
        if (ret < 0) perror("write");
        return ret;
    }
    ssize_t read(void *buffer, size_t length) {
        size_t rest = length;
        do {
            ssize_t ret = ::read(fd, buffer, length);
            if (ret < 0) {
                perror("read");
                return rest;
            }
            rest -= ret;
            buffer += ret;
        } while (rest) ;
        return length;
    }
    ~Serial() {
        if (close(fd) < 0) perror("close");
    }
};

}

#endif
