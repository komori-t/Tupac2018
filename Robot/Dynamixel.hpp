#ifndef __Dynamixel__
#define __Dynamixel__

#include "Servo.hpp"
#include "ByteUnion.hpp"

class DynamixelCheckSumCalculator
{
    static const uint16_t dynamicTable[256];
    static constexpr uint16_t staticTable[256] = {
        0x0000,
        0x8005, 0x800F, 0x000A, 0x801B, 0x001E, 0x0014, 0x8011,
        0x8033, 0x0036, 0x003C, 0x8039, 0x0028, 0x802D, 0x8027,
        0x0022, 0x8063, 0x0066, 0x006C, 0x8069, 0x0078, 0x807D,
        0x8077, 0x0072, 0x0050, 0x8055, 0x805F, 0x005A, 0x804B,
        0x004E, 0x0044, 0x8041, 0x80C3, 0x00C6, 0x00CC, 0x80C9,
        0x00D8, 0x80DD, 0x80D7, 0x00D2, 0x00F0, 0x80F5, 0x80FF,
        0x00FA, 0x80EB, 0x00EE, 0x00E4, 0x80E1, 0x00A0, 0x80A5,
        0x80AF, 0x00AA, 0x80BB, 0x00BE, 0x00B4, 0x80B1, 0x8093,
        0x0096, 0x009C, 0x8099, 0x0088, 0x808D, 0x8087, 0x0082,
        0x8183, 0x0186, 0x018C, 0x8189, 0x0198, 0x819D, 0x8197,
        0x0192, 0x01B0, 0x81B5, 0x81BF, 0x01BA, 0x81AB, 0x01AE,
        0x01A4, 0x81A1, 0x01E0, 0x81E5, 0x81EF, 0x01EA, 0x81FB,
        0x01FE, 0x01F4, 0x81F1, 0x81D3, 0x01D6, 0x01DC, 0x81D9,
        0x01C8, 0x81CD, 0x81C7, 0x01C2, 0x0140, 0x8145, 0x814F,
        0x014A, 0x815B, 0x015E, 0x0154, 0x8151, 0x8173, 0x0176,
        0x017C, 0x8179, 0x0168, 0x816D, 0x8167, 0x0162, 0x8123,
        0x0126, 0x012C, 0x8129, 0x0138, 0x813D, 0x8137, 0x0132,
        0x0110, 0x8115, 0x811F, 0x011A, 0x810B, 0x010E, 0x0104,
        0x8101, 0x8303, 0x0306, 0x030C, 0x8309, 0x0318, 0x831D,
        0x8317, 0x0312, 0x0330, 0x8335, 0x833F, 0x033A, 0x832B,
        0x032E, 0x0324, 0x8321, 0x0360, 0x8365, 0x836F, 0x036A,
        0x837B, 0x037E, 0x0374, 0x8371, 0x8353, 0x0356, 0x035C,
        0x8359, 0x0348, 0x834D, 0x8347, 0x0342, 0x03C0, 0x83C5,
        0x83CF, 0x03CA, 0x83DB, 0x03DE, 0x03D4, 0x83D1, 0x83F3,
        0x03F6, 0x03FC, 0x83F9, 0x03E8, 0x83ED, 0x83E7, 0x03E2,
        0x83A3, 0x03A6, 0x03AC, 0x83A9, 0x03B8, 0x83BD, 0x83B7,
        0x03B2, 0x0390, 0x8395, 0x839F, 0x039A, 0x838B, 0x038E,
        0x0384, 0x8381, 0x0280, 0x8285, 0x828F, 0x028A, 0x829B,
        0x029E, 0x0294, 0x8291, 0x82B3, 0x02B6, 0x02BC, 0x82B9,
        0x02A8, 0x82AD, 0x82A7, 0x02A2, 0x82E3, 0x02E6, 0x02EC,
        0x82E9, 0x02F8, 0x82FD, 0x82F7, 0x02F2, 0x02D0, 0x82D5,
        0x82DF, 0x02DA, 0x82CB, 0x02CE, 0x02C4, 0x82C1, 0x8243,
        0x0246, 0x024C, 0x8249, 0x0258, 0x825D, 0x8257, 0x0252,
        0x0270, 0x8275, 0x827F, 0x027A, 0x826B, 0x026E, 0x0264,
        0x8261, 0x0220, 0x8225, 0x822F, 0x022A, 0x823B, 0x023E,
        0x0234, 0x8231, 0x8213, 0x0216, 0x021C, 0x8219, 0x0208,
        0x820D, 0x8207, 0x0202
    };
public:
    static uint16_t calc(uint16_t crc_accum) {
        return crc_accum;
    }
    template <typename T, typename... Args>
    static uint16_t calc(uint16_t crc_accum, T& array, Args&... args) {
        uint8_t i;
        for (uint8_t data : array) {
            i = (crc_accum >> 8) ^ data;
            crc_accum = (crc_accum << 8) ^ dynamicTable[i];
        }
        return calc(crc_accum, args...);
    }
    template <size_t length>
    static constexpr uint16_t calc(const std::array<uint8_t, length> array) {
        uint16_t crc_accum = 0;
        uint8_t i = 0;
        for (size_t index = 0; index < length; ++index) {
            /* This loop should be range based for in C++17 */
            i = (crc_accum >> 8) ^ array[index];
            crc_accum = (crc_accum << 8) ^ staticTable[i];
        }
        return crc_accum;
    }
};

template <uint8_t id>
class Dynamixel : public Servo {
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
    void writeMemory(Serial::Error *error) {
        constexpr std::array<uint8_t, 11> packetForChecksum({
            0xFF, 0xFF, 0xFD, /* Header */
            0x00, /* Reserved */
            id,
            6, 0, /* Length: data + checksum (little endian) */
            3, /* Write Instruction */
            address & 0xFF, address >> 8,
            value
        });
        constexpr uint16_t checksum = DynamixelCheckSumCalculator::calc(packetForChecksum);
        /* C++17 may make this smarter (value_type& operator [] becoms constexpr) */
        constexpr std::array<uint8_t, 13> packet({
            0xFF, 0xFF, 0xFD, 0x00, id, 6, 0, 3, address & 0xFF, address >> 8, value,
            static_cast<uint8_t>(checksum & 0xFF), static_cast<uint8_t>(checksum >> 8)
        });
        std::array<uint8_t, 11> response;
        if (error) {
            *error = this->serial->transfer(response, packet);
        } else {
            this->serial->transfer(response, packet);
        }
        /* TODO: check response */
    }
    template <uint16_t address, typename T>
    void writeMemory(T data, Serial::Error *error) {
        ByteUnion<T> dat(data);
        constexpr std::array<uint8_t, 10> header({
            0xFF, 0xFF, 0xFD, /* Header */
            0x00, /* Reserved */
            id,
            sizeof(T) + 5, 0, /* Length: data + checksum (little endian) */
            3, /* Write Instruction */
            address & 0xFF, address >> 8
        });
        auto dataArray = dat.arrayObj();
        constexpr uint16_t headerChecksum = DynamixelCheckSumCalculator::calc(header);
        ByteUnion<uint16_t> checksum(DynamixelCheckSumCalculator::calc(headerChecksum, dataArray));
        std::array<uint8_t, 11> response;
        auto checksumArray = checksum.arrayObj();
        if (error) {
            *error = this->serial->transfer(response, header, dataArray, checksumArray);
        } else {
            this->serial->transfer(response, header, dataArray, checksumArray);
        }
        /* TODO: check response */
    }
    template <uint16_t address, typename T>
    T readMemory(Serial::Error *error) {
        constexpr std::array<uint8_t, 12> packetForChecksum({
            0xFF, 0xFF, 0xFD, /* Header */
            0x00, /* Reserved */
            id,
            7, 0, /* Length (little endian) */
            2, /* Read Instruction */
            address & 0xFF, address >> 8,
            sizeof(T), 0, /* Read size */
        });
        constexpr uint16_t checksum = DynamixelCheckSumCalculator::calc(packetForChecksum);
        /* C++17 may make this smarter (value_type& operator [] becoms constexpr) */
        constexpr std::array<uint8_t, 14> fullPacket({
            0xFF, 0xFF, 0xFD, 0x00, id, 7, 0, 2, address & 0xFF, address >> 8, sizeof(T), 0,
            static_cast<uint8_t>(checksum & 0xFF), static_cast<uint8_t>(checksum >> 8)
        });
        std::array<uint8_t, 11 + sizeof(T)> response;
        Serial::Error ret = this->serial->transfer(response, fullPacket);
        StatusPacket<T> status;
        std::copy(response.begin(), response.end(), std::begin(status.raw));
        if (error) {
            *error = ret;
#if 0
            if (ret == Serial::Error::NoError) {
                std::array<uint8_t, 9 + sizeof(T)> arrayForChecksum;
                std::copy(response.begin(), response.end() - 2, arrayForChecksum.begin());
                uint16_t checksum = DynamixelCheckSumCalculator::calc(0, arrayForChecksum);
                if (checksum != status.checksum) {
                    *error = Serial::Error::ReadFailed;
                }
            }
#endif
        }
        return status.data;
    }
    
public:
    Dynamixel(Serial *_serial) : Servo(_serial) {};
    void setTorque(bool enable, Serial::Error *error = nullptr) {
        if (enable) {
            writeMemory<64, 1>(error);
        } else {
            writeMemory<64, 0>(error);
        }
    }
    void setPosition(int32_t position, Serial::Error *error = nullptr) {
        writeMemory<116>(position, error);
    }
    void setPosition(double position, Serial::Error *error = nullptr) {
        writeMemory<116>(static_cast<int32_t>(position * 4096 / 360), error);
    }
    double position(Serial::Error *error = nullptr) {
        return readMemory<132, int32_t>(error) * 360 / 4096;
    }
    int32_t intPosition(Serial::Error *error = nullptr) {
        return readMemory<132, int32_t>(error);
    }
    void setLED(bool led, Serial::Error *error = nullptr) {
        if (led) {
            writeMemory<65, 1>(error);
        } else {
            writeMemory<65, 0>(error);
        }
    }
    void reboot(Serial::Error *error = nullptr) {
        constexpr std::array<uint8_t, 8> header({
            0xFF, 0xFF, 0xFD, /* Header */
            0x00, /* Reserved */
            id,
            3, 0, /* Length: data + checksum (little endian) */
            8, /* Write Instruction */
        });
        constexpr uint16_t checksum = DynamixelCheckSumCalculator::calc(header);
        constexpr std::array<uint8_t, 10> packet({
            0xFF, 0xFF, 0xFD, 0x00, id, 3, 0, 8,
            static_cast<uint8_t>(checksum & 0xFF), static_cast<uint8_t>(checksum >> 8)
        });
        if (error) {
            *error = this->serial->transfer(packet);
        } else {
            this->serial->transfer(packet);
        }
        /* TODO: check response */
    }
    uint8_t hardwareStatus(Serial::Error *error = nullptr) {
        return readMemory<70, uint8_t>(error);
    }
    void rebootIfNeeded(Serial::Error *error = nullptr) {
        if (hardwareStatus(error)) reboot(error);
    }
    uint16_t current(Serial::Error *error = nullptr) {
        return readMemory<126, uint16_t>(error);
    }
};

#endif
