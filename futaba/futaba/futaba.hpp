#ifndef __futaba__
#define __futaba__

#include <cstdint>
#include <array>

/* The classes below are exported */
#pragma GCC visibility push(default)

class Futaba
{
    static constexpr uint8_t receiveBufSize = 32;
    uint8_t receiveBuffer[receiveBufSize];
    
public:
    class Delegate {
    public:
        virtual void futaba_send(Futaba *servo, uint8_t count, uint8_t data[count]) = 0;
        virtual void futaba_receive(Futaba *servo, uint8_t *count, uint8_t *data) = 0;
        virtual void futaba_takeMutex(Futaba *servo) = 0;
        virtual void futaba_releaseMutex(Futaba *servo) = 0;
    };
    Delegate *delegate;
    uint8_t id;
    Futaba(Delegate *delegate, uint8_t id);
    template <uint8_t length>
    struct ShortPacket {
        uint8_t flag = 0;
        uint8_t address;
        std::array<uint8_t, length> data;
    };
    void transfer(uint8_t count, uint8_t data[count], uint8_t *receiveCount) {
        delegate->futaba_takeMutex(this);
        delegate->futaba_send(this, count, data);
        if (receiveCount) {
            delegate->futaba_receive(this, receiveCount, receiveBuffer);
        }
        delegate->futaba_releaseMutex(this);
    }
    template <uint8_t length>
    void sendShortPacket(ShortPacket<length> &packet, uint8_t *receiveCount) {
        uint8_t buf[length + 8] = {
            0xFA, 0xAF, id, packet.flag, packet.address, length, 1
        };
        std::copy(packet.data.begin(), packet.data.end(), &buf[7]);
        uint8_t checkSum = id ^ packet.flag ^ packet.address ^ length ^ 1;
        for (uint8_t byte : packet.data) {
            checkSum ^= byte;
        }
        buf[length + 7] = checkSum;
        transfer(length + 8, buf, receiveCount);
    }
    template <typename T>
    void writeRAM(uint8_t address, T value, bool *success) {
        Futaba::ShortPacket<sizeof(T)> packet;
        packet.address = address;
        union {
            T value;
            uint8_t array[sizeof(T)];
        } buf;
        buf.value = value;
        std::copy(buf.array, &buf.array[sizeof(T)], packet.data.begin());
        if (success) {
            packet.flag = 1;
            uint8_t count;
            sendShortPacket(packet, &count);
            *success = (count == 1 && receiveBuffer[0] == 0x07);
            if (! *success) {
                printf("%d 0x%X\n", count, receiveBuffer[0]);
            }
        } else {
            sendShortPacket(packet, nullptr);
        }
    }
    template <typename T>
    T readMemory(uint8_t address, bool &success) {
        success = false;
        uint8_t buf[8] = {
            0xFA, 0xAF, id, 0x0F, address, sizeof(T), 0,
            static_cast<uint8_t>(id ^ 0x0F ^ address ^ sizeof(T))
        };
        uint8_t count;
        transfer(8, buf, &count);
        if (count != 8 + sizeof(T)) {
            return 0;
        }
        union {
            struct {
                uint16_t header;
                uint8_t id;
                uint8_t flags;
                uint8_t address;
                uint8_t length;
                uint8_t count;
                T data;
                uint8_t checksum;
            };
            uint8_t array[8 + sizeof(T)];
        } rbuf;
        std::copy(receiveBuffer, &receiveBuffer[8 + sizeof(T)], rbuf.array);
        /* TODO: data check */
        success = true;
        return rbuf.data;
    }
    void setGoalPosition(int16_t position, bool *success = nullptr);
    void enableTorque(bool *success = nullptr);
    int16_t currentPosition(bool &success);
};

#pragma GCC visibility pop
#endif
