#include "UDPClient.h"
#include <stdio.h>
#include <sys/types.h>
#include <unistd.h>
#include <errno.h>
#include <stddef.h>
#include <string.h>

int udp_client_init(udp_client_ref client, udp_address_t *server)
{
	client->socket = socket(AF_INET, SOCK_DGRAM, 0);
	if (client->socket < 0) {
		perror("socket");
		return errno;
	}
	const int flag = 1;
	if (setsockopt(client->socket, SOL_SOCKET, SO_REUSEADDR, &flag, sizeof(flag)) < 0) {
		perror("setsockopt");
	}
	int ret = connect(client->socket, (struct sockaddr *)&server->address, server->addressLength);
	if (ret < 0) perror("connect");
	return 0;
}

ssize_t udp_client_read(udp_client_ref client, uint8_t *buf, size_t bufSize)
{
	return recv(client->socket, buf, bufSize, 0);
}

ssize_t udp_client_write(udp_client_ref client, const uint8_t *data, size_t length)
{
	ssize_t ret = write(client->socket, data, length);
	if (ret < 0) perror("write");
	return ret;
}

int udp_client_enable_broadcast(udp_client_ref client, int enable)
{
	if (setsockopt(client->socket, SOL_SOCKET, SO_BROADCAST, &enable, sizeof(enable)) < 0) {
		perror("setsockopt");
		return errno;
	}
	return 0;
}
