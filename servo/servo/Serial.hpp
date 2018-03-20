#ifndef __Serial__
#define __Serial__

#include <termios.h>
#include <unistd.h>
#include <sys/uio.h>
#include <sys/ioctl.h>
#include <array>
#include <pthread.h>

class Serial {
    int fd;
    termios options;
    pthread_mutex_t mutex = PTHREAD_MUTEX_INITIALIZER;
    void copyToIOVector(iovec *vectors) {}
    template <size_t length, typename ...Arrays>
    void copyToIOVector(iovec *vectors, const std::array<uint8_t, length> &array, Arrays&... arrays) {
        vectors->iov_base = const_cast<uint8_t *>(array.data());
        vectors->iov_len = length;
        copyToIOVector(++vectors, arrays...);
    }
    template <size_t length>
    ssize_t write(const std::array<uint8_t, length> &array) {
        return ::write(fd, array.data(), length);
    }
    
    template <size_t length1, typename T1, typename... T2>
    ssize_t write(const std::array<uint8_t, length1> &data1, T1 &data2, T2&... datas) {
        std::array<iovec, 2 + sizeof...(T2)> vectors;
        copyToIOVector(vectors.data(), data1, data2, datas...);
        writev(fd, vectors.data(), vectors.size());
        return 0;
    }
public:
    Serial(const char *dev, speed_t baud);
    void changeBaud(speed_t baud);
    ~Serial();
    template <size_t readLength, size_t writeLength1, typename... T>
    bool transfer(std::array<uint8_t, readLength> &readBuffer,
                  const std::array<uint8_t, writeLength1> &writeData, const T&... datas) {
        pthread_mutex_lock(&mutex);
#if 0
        int avail;
        ioctl(fd, FIONREAD, &avail);
        if (avail) {
            uint8_t dummy[avail];
            read(fd, dummy, avail);
        }
#endif
        write(writeData, datas...);
        size_t len = readLength;
        do {
            len -= read(fd, readBuffer.data(), readLength);
        } while (len) ;
        pthread_mutex_unlock(&mutex);
        return true;
    }
    template <size_t writeLength1, typename... T>
    bool transfer(const std::array<uint8_t, writeLength1> &writeData, const T&... datas) {
        pthread_mutex_lock(&mutex);
        write(writeData, datas...);
        pthread_mutex_unlock(&mutex);
        return true;
    }
};

#endif
