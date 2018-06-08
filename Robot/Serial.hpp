#ifndef __Serial__
#define __Serial__

#include <termios.h>
#include <unistd.h>
#include <sys/uio.h>
#include <sys/ioctl.h>
#include <array>
#include <pthread.h>
#include <errno.h>
#include <mutex>
#include <chrono>

class Serial {
    int fd;
    termios options;
    std::mutex mutex;
    size_t __attribute__((const)) copyToIOVector(const iovec __attribute__((unused)) *vectors) {
        return 0;
    }
    template <size_t length, typename ...Arrays>
    size_t copyToIOVector(iovec *vectors, const std::array<uint8_t, length> &array, Arrays&... arrays) {
        vectors->iov_base = const_cast<uint8_t *>(array.data());
        vectors->iov_len = length;
        return length + copyToIOVector(++vectors, arrays...);
    }
    template <size_t length>
    bool write(const std::array<uint8_t, length> &array) {
        ssize_t writeLen = ::write(fd, array.data(), length);
        if (writeLen < 0) {
            perror("write");
            return false;
        }
        return writeLen == length;
    }
    
    template <size_t length1, typename T1, typename... T2>
    bool write(const std::array<uint8_t, length1> &data1, T1 &data2, T2&... datas) {
        std::array<iovec, 2 + sizeof...(T2)> vectors;
        size_t fullLength = copyToIOVector(vectors.data(), data1, data2, datas...);
        ssize_t writeLen = writev(fd, vectors.data(), vectors.size());
        if (writeLen < 0) {
            perror("writev");
            return false;
        }
        return static_cast<size_t>(writeLen) == fullLength;
    }
public:
    enum class Error {
        NoError,
        WriteFailed,
        ReadFailed,
        ReadTimeout,
    };
    
    Serial(const char *dev, speed_t baud, bool &success);
    bool changeBaud(speed_t baud);
    ~Serial();
    template <size_t readLength, size_t writeLength1, typename... T>
    Error transfer(std::array<uint8_t, readLength> &readBuffer,
                   const std::array<uint8_t, writeLength1> &writeData, const T&... datas) {
        std::lock_guard<std::mutex> lock(mutex);
#if 0
        int avail;
        ioctl(fd, FIONREAD, &avail);
        if (avail) {
            uint8_t dummy[avail];
            read(fd, dummy, avail);
        }
#endif
        if (! write(writeData, datas...)) {
            return Error::WriteFailed;
        }
        auto limit = std::chrono::system_clock::now() + std::chrono::milliseconds(100);
        size_t rest = readLength;
        uint8_t *readP = readBuffer.data();
        ssize_t readLen;
        do {
            if (std::chrono::system_clock::now() > limit) {
                return Error::ReadTimeout;
            }
            readLen = read(fd, readP, readLength);
            if (readLen < 0) {
                if (errno != EINTR) {
                    perror("read");
                    return Error::ReadFailed;
                }
            }
            rest -= readLen;
            readP += readLen;
        } while (rest) ;
        return Error::NoError;
    }
    template <size_t writeLength1, typename... T>
    Error transfer(const std::array<uint8_t, writeLength1> &writeData, const T&... datas) {
        std::lock_guard<std::mutex> lock(mutex);
        return write(writeData, datas...) ? Error::NoError : Error::WriteFailed;
    }
};

#endif
