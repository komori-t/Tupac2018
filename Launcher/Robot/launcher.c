#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <stdio.h>
#include <sys/wait.h>
#include <stdlib.h>
#include <unistd.h>
#include <string.h>
#include <signal.h>
#include <errno.h>
#include <pthread.h>
#include "launcher.h"
#include "UDPServer.h"

void checkStatus(const char *fname, ssize_t result, udp_server_ref udp)
{
    if (result < 0) {
        const char *msg = strerror(errno);
        udp_server_write(udp, (const uint8_t *)fname, strlen(fname));
        udp_server_write(udp, (const uint8_t *)": ", 2);
        udp_server_write(udp, (const uint8_t *)msg, strlen(msg));
        udp_server_write(udp, (const uint8_t *)"\n", 2); /* with '\0' */
        exit(EXIT_FAILURE);
    }
}

void _checkStatus(const char *fname, ssize_t result, udp_server_ref udp)
{
    if (result < 0) {
        const char *msg = strerror(errno);
        udp_server_write(udp, (const uint8_t *)fname, strlen(fname));
        udp_server_write(udp, (const uint8_t *)": ", 2);
        udp_server_write(udp, (const uint8_t *)msg, strlen(msg));
        udp_server_write(udp, (const uint8_t *)"\n", 2); /* with '\0' */
        _exit(EXIT_FAILURE);
    }
}

typedef struct {
    udp_server_ref udp;
    pid_t childPID;
} threadarg_t;

void *hostCommandReader(void *arg)
{
    threadarg_t *args = (threadarg_t *)arg;
    udp_server_ref udp = args->udp;
    pid_t childPID = args->childPID;
    while (1) {
        uint8_t buf;
        ssize_t size = udp_server_read(udp, &buf, 1);
        if (size < 0) {
            checkStatus("read", size, udp);
        }
        switch (buf) {
            case LAUNCHER_MSG_TERMINATE:
                kill(childPID, SIGINT);
                break;
            case LAUNCHER_MSG_POWEROFF:
            {
                const char msg[] = "Bye!\n";
                udp_server_write(udp, (const uint8_t *)msg, sizeof(msg));
                kill(childPID, SIGINT);
                int ret = execl("/sbin/poweroff", "poweroff", (char *)NULL);
                checkStatus("execl", ret, udp);
            }
                break;
            default:
                break;
        }
    }
    return NULL;
}

int main()
{
    udp_address_t hostAddress;
    udp_server_t udp;
    udp_server_init(&udp, LAUNCHER_ROBOT_PORT);

    while (1) {
        uint8_t commandBuf;
        ssize_t size = udp_server_readFrom(&udp, &commandBuf, sizeof(commandBuf), &hostAddress);
        checkStatus("udp_client_read", size, &udp);
        if (size != 1) continue;
        switch (commandBuf) {
            case LAUNCHER_MSG_LAUNCH:
            {
                const char msg[] = "Launching\n";
                udp_server_write(&udp, (const uint8_t *)msg, sizeof(msg));
                break;
            }
            case LAUNCHER_MSG_POWEROFF:
            {
                const char msg[] = "Bye!\n";
                udp_server_write(udp, (const uint8_t *)msg, sizeof(msg));
                int ret = execl("/sbin/poweroff", "poweroff", (char *)NULL);
                checkStatus("execl", ret, &udp);
            }
                return 0;
            default:
                continue;
        }        

        hostAddress.address.sin_port = htons(LAUNCHER_HOST_PORT);

        int pipefd[2];
        checkStatus("pipe", pipe(pipefd), &udp);

        pid_t childPID = fork();
        checkStatus("fork", childPID, &udp);

        if (childPID == 0) {
            char cmd[] = "../../Robot/robot 1>&0 2>&0";
            cmd[21] = '0' + pipefd[1];
            cmd[26] = cmd[18];
            int ret = execl("/bin/sh", "sh", "-c", cmd, (char *)NULL);
            _checkStatus("execl", ret, &udp);
        } else {
            close(pipefd[1]);
            threadarg_t arg;
            arg.udp = &udp;
            arg.childPID = childPID;
            pthread_t thread;
            pthread_create(&thread, NULL, hostCommandReader, &arg);
            char buf[256];
            while (1) {
                ssize_t ret = read(pipefd[0], buf, sizeof(buf));
                if (ret == 0) {
                    pthread_cancel(thread);
                    const char msg[] = "Robot Program Done\n";
                    udp_server_writeTo(&udp, (const uint8_t *)msg, sizeof(msg), &hostAddress);
                    break;
                } else if (ret < 0) {
                    checkStatus("read", ret, &udp);
                } else {
                    udp_server_writeTo(&udp, (const uint8_t *)buf, ret, &hostAddress);
                }
            }
        }
    }

    return 0;
}
