#ifndef __SysfsGPIO__
#define __SysfsGPIO__

#include <fcntl.h>
#include <stdio.h>
#include <unistd.h>
#include <string.h>
#include <stdint.h>
#include <poll.h>

class SysfsGPIO
{
    int fd = -1;

public:
    SysfsGPIO(const char *path, int flags) {
        fd = open(path, flags);
        if (fd < 0) perror("open");
    }
    SysfsGPIO(uint8_t pin, const char *file, int flags) {
        char path[21 + 3 + strlen(file) + 1];
        snprintf(path, sizeof(path), "/sys/class/gpio/gpio%u/%s", pin, file);
        fd = open(path, flags);
        if (fd < 0) perror("open");
    }
    ~SysfsGPIO() {
        if (close(fd) < 0) perror("close");
    }
    ssize_t pwrite(const void *buf, size_t count) {
        ssize_t ret = ::write(fd, buf, count);
        if (ret < 0) perror("write");
        return ret;
    }
    ssize_t pread(void *buf, size_t count) {
        ssize_t ret = ::pread(fd, buf, count, 0);
        if (ret < 0) perror("pread");
        return ret;
    }
    int poll(int timeout = -1) {
        struct pollfd pfd = {
            .fd = fd,
            .events = POLLPRI | POLLERR
        };
        int ret = ::poll(&pfd, 1, timeout);
        if (ret < 0) perror("poll");
        return ret;
    }
};

#endif
