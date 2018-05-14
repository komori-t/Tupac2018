#ifndef __ServoConverter__
#define __ServoConverter__

#include "RDTPPacket.h"
#include "GamepadConstants.h"

#ifdef __cplusplus
extern "C" {
#endif

extern void ServoConverter_setServoSpeed(RDTPPacketComponent servo, int speed);
void ServoConverter_convert(GamepadStickAxis axis, int value);
    
#ifdef __cplusplus
}
#endif

#endif
