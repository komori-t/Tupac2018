#include "futaba.hpp"

Futaba::Futaba(Futaba::Delegate *_delegate, uint8_t _id) : delegate(_delegate), id(_id)
{
    
}

void Futaba::setGoalPosition(int16_t position, bool *success)
{
    writeRAM(0x1E, position, success);
}

void Futaba::enableTorque(bool *success)
{
    writeRAM(0x24, static_cast<uint8_t>(1), success);
}

int16_t Futaba::currentPosition(bool &success)
{
    return readMemory<int16_t>(0x2A, success);
}
