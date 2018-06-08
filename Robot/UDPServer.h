#ifndef __UDPServer__
#define __UDPServer__

#ifdef __cplusplus
extern "C" {
#endif

#include <stdint.h>
#include <sys/types.h>

typedef struct {
    int socket;
} udp_server_t;

typedef udp_server_t* udp_server_ref;

int udp_server_init(udp_server_ref server, uint16_t port);
ssize_t udp_server_read(udp_server_ref server, uint8_t *buf, size_t bufSize);
ssize_t udp_server_write(udp_server_ref server, const uint8_t *data, size_t length);

#ifdef __cplusplus
}
#endif

#endif
