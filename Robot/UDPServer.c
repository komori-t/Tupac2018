#include "UDPServer.h"
#include <stdio.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <unistd.h>
#include <errno.h>
#include <stddef.h>

int udp_server_init(udp_server_ref server, uint16_t port)
{
	server->socket = socket(AF_INET, SOCK_DGRAM, 0);
	if (server->socket < 0) {
		perror("socket");
		return errno;
	}
	const char flag = 1;
	setsockopt(server->socket, SOL_SOCKET, SO_REUSEADDR, &flag, 1);
	struct sockaddr_in addr;
	addr.sin_family = AF_INET;
	addr.sin_port = htons(port);
	addr.sin_addr.s_addr = INADDR_ANY;
	if (bind(server->socket, (struct sockaddr *)&addr, sizeof(addr)) < 0) {
		perror("bind");
		return errno;
	}
	return 0;
}

ssize_t udp_server_read(udp_server_ref server, uint8_t *buf, size_t bufSize)
{
	return recv(server->socket, buf, bufSize, 0);
}

ssize_t udp_server_write(udp_server_ref server, const uint8_t *data, size_t length)
{
	return write(server->socket, data, length);
}
