#include "serial.h"
#include <stdio.h>
#include <unistd.h>

void handler(uint8_t *data, size_t count)
{
    printf("READ: ");
    do {
        printf("%c(%d)", *data, *data);
        ++data;
    } while (--count) ;
    printf("\n");
}

int main()
{
    serial_t serial;
    serial_init(&serial, "/dev/ttyACM0", B230400, handler);
    char buf[32];
    while (1) {
        fgets(buf, 32, stdin);
        int size = 0;
        for (int i = 0; buf[i] != '\n'; ++i) size++;
        serial_write(&serial, (uint8_t *)buf, size);
    }
    return 0;
}

