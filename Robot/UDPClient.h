#ifndef __UDPClient__
#define __UDPClient__

#ifdef __cplusplus
extern "C" {
#endif

#include <stdint.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include "UDPServer.h"

typedef struct {
    int socket;
} udp_client_t;

typedef udp_client_t* udp_client_ref;

int udp_client_init(udp_client_ref client, udp_address_t *server);
int udp_client_initWithoutConnecting(udp_client_ref client);
ssize_t udp_client_read(udp_client_ref client, uint8_t *buf, size_t bufSize);
ssize_t udp_client_write(udp_client_ref client, const uint8_t *data, size_t length);
int udp_client_enable_broadcast(udp_client_ref client, int enable);

#ifdef __cplusplus
}
#endif

#endif
