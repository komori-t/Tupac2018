#ifndef __RDTPPacket__
#define __RDTPPacket__

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif
    
#define RDTP_PORT (49153)
extern const char *RDTP_SearchingMessage;
extern const char *RDTP_DiscoverResponse;

typedef struct {
    int count;
    int valueCount;
    int16_t header;
    int8_t values[12];
} RDTPPacket;

typedef enum {
    LeftMotor    = 0,
    RightMotor   = 1,
    Servo0       = 2,
    Servo1       = 3,
    Servo2       = 4,
    Servo3       = 5,
    Servo4       = 6,
    Servo5       = 7,
    Servo6       = 8,
    Servo7       = 9,
    Servo8       = 10,
    Servo9       = 11,
    EnableServo  = 12,
    DisableServo = 13,
} RDTPPacketComponent;
    
typedef enum {
    StartVideo0 = 'V',
    StartVideo1 = 'v',
    StopVideo = 's',
    Shutdown = 'S',
} RDTPPacketCommand;
    
typedef enum {
    DataAvailable,
    EndOfPacket,
    CommandAvailable,
} RDTPPacketResult;
    
typedef union {
    struct {
        int16_t header;
        int8_t  values[12];
    };
    int8_t buffer[14];
} RDTPPacketBuffer;

void RDTPPacket_init(RDTPPacket *packet);
void RDTPPacket_initWithBytes(RDTPPacket *packet, int8_t *bytes, int length);
void RDTPPacket_updateValue(RDTPPacket *packet, RDTPPacketComponent component, int8_t value);
void RDTPPacket_setCommand(RDTPPacket *packet, RDTPPacketCommand command);
void RDTPPacket_getSendData(RDTPPacket *packet, RDTPPacketBuffer *buf, int *length);
RDTPPacketResult RDTPPacket_getReceiveData(RDTPPacket *packet, int8_t *value, RDTPPacketComponent *component);
RDTPPacketCommand RDTPPacket_getReceiveCommand(RDTPPacket *packet);

#ifdef __cplusplus
}
#endif

#endif
