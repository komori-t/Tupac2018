#ifndef __Futaba__
#define __Futaba__

#include "Servo.hpp"
#include "ByteUnion.hpp"

template <uint8_t id>
class Futaba : public Servo {
    template<size_t length>
    static constexpr uint8_t calcChecksum(const std::array<uint8_t, length> data) {
        uint8_t ret = data[0];
        for (size_t i = 1; i < length; ++i) {
            ret ^= data[i];
        }
        return ret;
    }
    template <uint8_t address, uint8_t value>
    void writeMemory(Serial::Error *error) {
        constexpr std::array<uint8_t, 6> packetForChecksum({
            id,
            0, /* No return packet */
            address,
            1,
            1, /* Count */
            value
        });
        constexpr uint8_t checksum = calcChecksum(packetForChecksum);
        constexpr std::array<uint8_t, 9> packet({
            0xFA, 0xAF, id, 0, address, 1, 1, value, checksum
        });
        if (error) {
            *error = this->serial->transfer(packet);
        } else {
            this->serial->transfer(packet);
        }
    }
    template <uint8_t address, typename T>
    void writeMemory(T data, Serial::Error *error) {
        constexpr std::array<uint8_t, 2> header({
            0xFA, 0xAF, /* Header */
        });
        constexpr std::array<uint8_t, 5> packetForChecksum({
            id,
            0, /* No return packet */
            address,
            sizeof(data),
            1, /* Count */
        });
        constexpr uint8_t checksum = calcChecksum(packetForChecksum);
        uint8_t checksumVar = checksum;
        ByteUnion<T> dataByte(data);
        for (uint8_t v : dataByte.array) {
            checksumVar ^= v;
        }
        auto dataArray = dataByte.arrayObj();
        if (error) {
            *error = this->serial->transfer(header, packetForChecksum,
                                            dataArray, std::array<uint8_t, 1>({checksumVar}));
        } else {
            this->serial->transfer(header, packetForChecksum, dataArray, std::array<uint8_t, 1>({checksumVar}));
        }
    }
    template <uint8_t address, typename T>
    T readMemory(Serial::Error *error) {
        constexpr std::array<uint8_t, 8> packet({
            0xFA, 0xAF, /* Header */
            id,
            0x0F, /* Flag */
            address,
            sizeof(T),
            0, /* Count */
            id ^ 0x0F ^ address ^ sizeof(T) /* Checksum */
        });
        std::array<uint8_t, 8 + sizeof(T)> response;
        Serial::Error ret = this->serial->transfer(response, packet);
        union ReturnPacket {
            uint8_t raw[8 + sizeof(T)];
            struct __attribute__((packed)) {
                uint16_t header;
                uint8_t identifier;
                uint8_t flags;
                uint8_t registerAddress;
                uint8_t length;
                uint8_t count;
                T data;
                uint8_t checksum;
            };
        };
        ReturnPacket rePacket;
        std::copy(response.begin(), response.end(), std::begin(rePacket.raw));
        checksum = identifier;
        for (int i = 3; i < sizeof(rePacket) - 1; ++i) {
            checksum ^= rePacket.raw[i];
        }
        if (checksum == rePacket.checksum) {
            if (error) {
                *error = ret;
            }
            return rePacket.data;
        } else {
            *error = Serial::Error::ReadFailed;
            return 0;
        }
    }
    
public:
    Futaba(Serial *_serial) : Servo(_serial) {}
    void setTorque(bool enable, Serial::Error *error = nullptr) {
        if (enable) {
            writeMemory<0x24, 1>(error);
        } else {
            writeMemory<0x24, 0>(error);
        }
    }
    void setPosition(double position, Serial::Error *error = nullptr) {
        writeMemory<0x1E>(static_cast<int16_t>(position * 10), error);
    }
    void setPosition(int32_t position, Serial::Error *error = nullptr) {
        writeMemory<0x1E>(static_cast<int16_t>(position), error);
    }
    int32_t intPosition(Serial::Error *error = nullptr) {
        return static_cast<int32_t>(readMemory<0x2A, int16_t>(error));
    }
    double position(Serial::Error *error = nullptr) {
        return readMemory<0x2A, int16_t>(error) / 10;
    }
    void reboot(Serial::Error *error = nullptr) {
        constexpr std::array<uint8_t, 8> packet({
            0xFA, 0xAF, /* Header */
            id,
            0x20, /* Flag */
            0xFF,
            0,
            0, /* Count */
            id ^ 0x20 ^ 0xFF /* Checksum */
        });
        *error = this->serial->transfer(packet);
    }
    void rebootIfNeeded(Serial::Error *error = nullptr) {
        constexpr std::array<uint8_t, 8> packet({
            0xFA, 0xAF, /* Header */
            id,
            0x0F, /* Flag */
            0x04,
            1,
            0, /* Count */
            id ^ 0x0F ^ 0x04 ^ 1 /* Checksum */
        });
        std::array<uint8_t, 9> response;
        Serial::Error ret = this->serial->transfer(response, packet);
        if (ret == Serial::Error::NoError && response[3]) {
            reboot(error);
        } else {
            *error = ret;
        }
    }
    uint16_t current(Serial::Error *error = nullptr) {
        return readMemory<0x30, uint16_t>(error);
    }
};

#endif
