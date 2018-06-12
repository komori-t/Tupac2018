#ifndef __I2C__
#define __I2C__

#include <linux/i2c.h>
#include <linux/i2c-dev.h>
#include <sys/ioctl.h>
#include <fcntl.h>
#include <stdint.h>
#include <unistd.h>
#include <stdio.h>

class I2C
{
    int fd;
    struct i2c_msg writeMsg;
    struct i2c_msg readMsg;

public:
    I2C(const char *dev) {
        fd = open(dev, O_RDWR);
        if (fd < 0) {
            perror("open");
            return;
        }
        writeMsg.flags = 0;
        readMsg.flags = I2C_M_RD;
    }
    int read(int address, char *data, int length, bool repeated = false) {
        readMsg.addr = address;
        readMsg.len = length;
        readMsg.buf = reinterpret_cast<uint8_t *>(data);
        struct i2c_rdwr_ioctl_data ioData;
        struct i2c_msg msgs[2] = {writeMsg, readMsg};
        ioData.msgs = msgs;
        ioData.nmsgs = 2;
        if (ioctl(fd, I2C_RDWR, &ioData) < 0) {
            perror("ioctl");
            return 1;
        }
        return 0;
    }
    int write(int address, const char *data, int length, bool repeated = false) {
        writeMsg.addr = address;
        writeMsg.len = length;
        writeMsg.buf = const_cast<uint8_t *>(reinterpret_cast<const uint8_t *>(data));
        if (repeated) {
            return 0;
        } else {
            struct i2c_rdwr_ioctl_data data;
            data.msgs = &writeMsg;
            data.nmsgs = 1;
            if (ioctl(fd, I2C_RDWR, &data) < 0) {
                perror("ioctl");
                return 1;
            } else {
                return 0;
            }
        }
    }
    ~I2C() {
        if (close(fd) < 0) perror("close");
    }
};

#endif
