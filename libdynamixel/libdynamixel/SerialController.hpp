#ifndef __SerialController__
#define __SerialController__

#include <cstdint>
#include <cstddef>
#include <array>
#include <cstdio>

class SerialController {
public:
    class Delegate {
    public:
        virtual void serialControllerWrite(SerialController *controller, uint8_t *data, size_t length) = 0;
    };
    SerialController(Delegate *delegate);
    void readCallback(uint8_t *data, size_t length);
    Delegate *delegate;
    template <size_t size>
    bool write(uint8_t id, std::array<uint8_t, size> &data) {
        for (uint8_t v : data) {
            printf("%d\n", v);
        }
        return true;
    }
    template <typename T>
    bool write(uint8_t id, uint16_t address, T data) {
        union {
            struct pack {
                uint8_t instruction = 3;
                uint16_t rawaddress = address;
                T rawdata = data;
            };
            uint8_t byte[sizeof(pack)];
        } buf;
        std::array<uint8_t, sizeof(buf)> raw;
        std::copy(std::begin(buf.byte), std::end(buf.byte), std::begin(raw));
        return write(id, raw);
    }
};

#endif
