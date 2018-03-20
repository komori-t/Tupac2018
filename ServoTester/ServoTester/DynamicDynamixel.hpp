#ifndef __DynamicDynamixel__
#define __DynamicDynamixel__

#include "DynamicServo.hpp"
#include "Dynamixel.hpp"

class DynamicDynamixel : public DynamicServo {
    template <typename DataType>
    union StatusPacket {
        uint8_t raw[11 + sizeof(DataType)];
        struct __attribute__((packed)) {
            uint32_t header;
            uint8_t identifier;
            uint16_t length;
            uint8_t instruction;
            uint8_t error;
            DataType data;
            uint16_t checksum;
        };
    };
    template <uint16_t address, uint8_t value>
    void writeMemory(bool *success) {
        std::array<uint8_t, 11> packetForChecksum({
            0xFF, 0xFF, 0xFD, /* Header */
            0x00, /* Reserved */
            id,
            6, 0, /* Length: data + checksum (little endian) */
            3, /* Write Instruction */
            address & 0xFF, address >> 8,
            value
        });
        uint16_t checksum = DynamixelCheckSumCalculator::calc(0, packetForChecksum);
        /* C++17 may make this smarter (value_type& operator [] becoms constexpr) */
        std::array<uint8_t, 13> packet({
            0xFF, 0xFF, 0xFD, 0x00, id, 6, 0, 3, address & 0xFF, address >> 8, value,
            static_cast<uint8_t>(checksum & 0xFF), static_cast<uint8_t>(checksum >> 8)
        });
        std::array<uint8_t, 11> response;
        if (success) {
            *success = this->serial->transfer(response, packet);
        } else {
            this->serial->transfer(response, packet);
        }
        /* TODO: check response */
    }
    template <uint16_t address, typename T>
    void writeMemory(T data, bool *success) {
        ByteUnion<T> dat(data);
        std::array<uint8_t, 10> header({
            0xFF, 0xFF, 0xFD, /* Header */
            0x00, /* Reserved */
            id,
            sizeof(T) + 5, 0, /* Length: data + checksum (little endian) */
            3, /* Write Instruction */
            address & 0xFF, address >> 8
        });
        auto dataArray = dat.arrayObj();
        uint16_t headerChecksum = DynamixelCheckSumCalculator::calc(0, header);
        ByteUnion<uint16_t> checksum(DynamixelCheckSumCalculator::calc(headerChecksum, dataArray));
        std::array<uint8_t, 11> response;
        auto checksumArray = checksum.arrayObj();
        if (success) {
            *success = this->serial->transfer(response, header, dataArray, checksumArray);
        } else {
            this->serial->transfer(response, header, dataArray, checksumArray);
        }
        /* TODO: check response */
    }
    template <uint16_t address, typename T>
    T readMemory(bool *success) {
        std::array<uint8_t, 12> packetForChecksum({
            0xFF, 0xFF, 0xFD, /* Header */
            0x00, /* Reserved */
            id,
            7, 0, /* Length (little endian) */
            2, /* Read Instruction */
            address & 0xFF, address >> 8,
            sizeof(T), 0, /* Read size */
        });
        uint16_t checksum = DynamixelCheckSumCalculator::calc(0, packetForChecksum);
        /* C++17 may make this smarter (value_type& operator [] becoms constexpr) */
        std::array<uint8_t, 14> fullPacket({
            0xFF, 0xFF, 0xFD, 0x00, id, 7, 0, 2, address & 0xFF, address >> 8, sizeof(T), 0,
            static_cast<uint8_t>(checksum & 0xFF), static_cast<uint8_t>(checksum >> 8)
        });
        std::array<uint8_t, 11 + sizeof(T)> response;
        bool ret = this->serial->transfer(response, fullPacket);
        StatusPacket<T> status;
        std::copy(response.begin(), response.end(), std::begin(status.raw));
        /* TODO: check response */
        if (success) {
            if (ret) {
                std::array<uint8_t, 9 + sizeof(T)> arrayForChecksum;
                std::copy(response.begin(), response.end() - 2, arrayForChecksum.begin());
                uint16_t checksum = DynamixelCheckSumCalculator::calc(0, arrayForChecksum);
                *success = checksum == status.checksum;
            } else {
                *success = false;
            }
        }
        return status.data;
    }
    
public:
    DynamicDynamixel(Serial *serial, uint8_t id) : DynamicServo(serial, id) {}
    void setTorque(bool enable, bool *success = nullptr) {
        if (enable) {
            writeMemory<64, 1>(success);
        } else {
            writeMemory<64, 0>(success);
        }
    }
    void setPosition(int32_t position, bool *success = nullptr) {
        writeMemory<116>(position, success);
    }
    void setPosition(double position, bool *success = nullptr) {
        writeMemory<116>(static_cast<int32_t>(position * 4096 / 180), success);
    }
    double position(bool *success = nullptr) {
        return readMemory<132, int32_t>(success) * 360 / 4096;
    }
    int32_t intPosition(bool *success = nullptr) {
        return readMemory<132, int32_t>(success);
    }
    void setID(uint8_t newID, bool *success) {
        setTorque(false);
        writeMemory<7>(newID, success);
        id = newID;
    }
    void setBaud(speed_t baud, bool *sucess) {
        setTorque(false);
        uint8_t speed = 0;
        switch (baud) {
            case B9600:
                speed = 0;
                break;
            case B57600:
                speed = 1;
                break;
            case B115200:
                speed = 2;
                break;
            default:
                return;
        }
        writeMemory<8>(speed, sucess);
        this->serial->changeBaud(speed);
    }
};

#endif
