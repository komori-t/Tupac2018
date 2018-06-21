#include "UDPServer.h"
#include "UDPClient.h"
#include "RDTPPacket.h"
#include "Serial.hpp"
#include "MbedSerial.hpp"
#include "Dynamixel.hpp"
#include "Futaba.hpp"
#include "ByteUnion.hpp"
#include "PAMovingAverage.hpp"
#include <signal.h>
#include <unistd.h>
#include <string.h>
#include <pthread.h>

#define NumOfServo 10
static constexpr uint16_t largeCurrent = 200;
static volatile uint8_t ackPacket[2];

void *voltageReader(void *arg)
{
    mbed::Serial *serial = reinterpret_cast<mbed::Serial *>(arg);
    uint8_t voltage;
    while (1) {
        serial->read(&voltage, 1);
        ackPacket[1] = voltage;
    }
    return NULL;
}

int main()
{
    setvbuf(stdout, NULL, _IONBF, 0);
    char frontCameraPath[] = "device=/dev/video0";
    char backCameraPath[] = "device=/dev/video0";
    const size_t numberIndex = strlen(frontCameraPath) - 1;
    {
        FILE *usbs = popen("lsusb", "r");
        char buffer[128];
        const char frontCameraID[] = ": ID 05a3:9420";
        const char backCameraID[] = ": ID 05a3:9230";
        const char thermalCameraID[] = ": ID 1e4e:0100";
        int frontCameraNumber = 0;
        int backCameraNumber = 0;
        int thermalCameraNumber = 0;
        while (reinterpret_cast<intptr_t>(fgets(buffer, sizeof(buffer), usbs)) > 0) {
            char *index;
            if ((index = strstr(buffer, frontCameraID))) {
                *index = '\0';
                frontCameraNumber = atoi(index - 3);
            } else if ((index = strstr(buffer, backCameraID))) {
                *index = '\0';
                backCameraNumber = atoi(index - 3);
            } else if ((index = strstr(buffer, thermalCameraID))) {
                *index = '\0';
                thermalCameraNumber = atoi(index - 3);
            }
        }
        if (frontCameraNumber < backCameraNumber && frontCameraNumber < thermalCameraNumber) {
            /* front first */
            frontCameraPath[numberIndex] = '0';
            if (backCameraNumber < thermalCameraNumber) {
                /* back second */
                backCameraPath[numberIndex] = '2';
            } else {
                /* thermal second */
                /* thermalCameraPath[numberIndex] = '2'; */
                backCameraPath[numberIndex] = '3';
            }
        } else if (backCameraNumber < thermalCameraNumber) {
            /* back first */
            backCameraPath[numberIndex] = '0';
            if (frontCameraNumber < thermalCameraNumber) {
                /* front second */
                frontCameraPath[numberIndex] = '1';
            } else {
                /* thermal second */
                /* thermalCemaraPath[numberIndex] = '1'; */
                frontCameraPath[numberIndex] = '2';
            }
        } else {
            /* thermal first */
            /* thermalCameraPath[numberIndex] = '0'; */
            if (frontCameraNumber < backCameraNumber) {
                /* front second */
                frontCameraPath[numberIndex] = '1';
                backCameraPath[numberIndex] = '3';
            } else {
                /* back second */
                backCameraPath[numberIndex] = '1';
                frontCameraPath[numberIndex] = '2';
            }
        }
        pclose(usbs);
    }
    bool success;
    mbed::Serial serial("/dev/ttyTHS2");
    serial.baud(B115200);
    int ttyIndex = -1;
    if (access("/dev/ttyUSB1", F_OK)) { /* why reversed ? */
        ttyIndex = 0;
    } else if (access("/dev/ttyUSB0", F_OK)) {
        ttyIndex = 1;
    } else {
        printf("Cannot find U2D2\n");
        return 1;
    }
    Serial servoSerial(ttyIndex == 0 ? "/dev/ttyUSB0" : "/dev/ttyUSB1",
                       B115200, success);

    Servo *servos[NumOfServo] = {
        new Futaba<1>(&servoSerial),    new Futaba<2>(&servoSerial),
        new Futaba<3>(&servoSerial),    new Dynamixel<1>(&servoSerial),
        new Dynamixel<2>(&servoSerial), new Dynamixel<3>(&servoSerial),
        new Dynamixel<4>(&servoSerial), new Dynamixel<5>(&servoSerial),
        new Dynamixel<6>(&servoSerial), new Dynamixel<7>(&servoSerial),
    };
    Serial::Error error;

    printf("Rebooting ... ");
    for (int i = 0; i < NumOfServo; ++i) {
        servos[i]->rebootIfNeeded(&error);
        if (error == Serial::Error::NoError) {
            printf("%d ", i);
        } else {
            printf("\nError: %d\n", static_cast<int>(error));
            return 1;
        }
    }
    puts("done");

    printf("Disabling Torque ... ");
    for (int i = 0; i < NumOfServo; ++i) {
        servos[i]->setTorque(false, &error);
        if (error == Serial::Error::NoError) {
            printf("%d ", i);
        } else {
            printf("\nError: %d\n", static_cast<int>(error));
            return 1;
        }
    }
    puts("done");

    udp_server_t server;
    udp_server_init(&server, RDTP_PORT);
    RDTPPacket packet;
    RDTPPacketBuffer buffer;
    char gstreamerAddressString[21];
    char gstreamerPortString[11];
    udp_client_t client;
    PAMovingAverage<uint16_t, 50> servo0CurrentAverage;
    pthread_t thread;
    pthread_create(&thread, NULL, voltageReader, &serial);

    snprintf(gstreamerPortString, sizeof(gstreamerPortString), "port=%hu", RDTP_PORT);
    {
        udp_address_t source;
        const ssize_t messageLength = strlen(RDTP_SearchingMessage);
        while (1) {
            ssize_t length = udp_server_readFrom(&server, (uint8_t *)buffer.buffer, sizeof(buffer), &source);
            if (length == messageLength && strncmp((char *)buffer.buffer, RDTP_SearchingMessage, messageLength) == 0) {
                udp_server_connect(&server, &source);
                const size_t responseLength = strlen(RDTP_DiscoverResponse);
                const size_t initialPacketLength = responseLength + sizeof(int32_t) * NumOfServo;
                uint8_t initialPacket[initialPacketLength];
                memcpy(initialPacket, RDTP_DiscoverResponse, responseLength);
                int32_t initialPositions[NumOfServo];
                for (int i = 0; i < NumOfServo; ++i) {
                    initialPositions[i] = servos[i]->intPosition(&error);
                }
                memcpy(&initialPacket[responseLength], initialPositions, sizeof(int32_t) * NumOfServo);
                udp_server_write(&server, initialPacket, initialPacketLength);
                source.address.sin_port = htons(RDTP_FEEDBACK_PORT);
                udp_client_init(&client, &source);
                break;
            }
        }
        ByteUnion<in_addr_t> address(source.address.sin_addr.s_addr);
        snprintf(gstreamerAddressString, sizeof(gstreamerAddressString), 
                 "host=%hhu.%hhu.%hhu.%hhu", address.array[0], address.array[1],
                 address.array[2], address.array[3]);
    }

    printf("Enabling Torque ... ");
    for (int i = 0; i < NumOfServo; ++i) {
        servos[i]->setTorque(true, &error);
        if (error == Serial::Error::NoError) {
            printf("%d ", i);
        } else {
            printf("\nError: %d\n", static_cast<int>(error));
            return 1;
        }
    }
    puts("done");

    uint8_t motorPower[2] = {0, 0};
    pid_t child = 0;
    ackPacket[0] = RDTP_ACK;
    if (error != Serial::Error::NoError) return (int)error;
    while (1) {
        ssize_t length = udp_server_read(&server, (uint8_t *)buffer.buffer, sizeof(buffer));
        udp_client_write(&client, const_cast<uint8_t *>(ackPacket), sizeof(ackPacket));
        RDTPPacket_initWithBytes(&packet, &buffer, length);
        int32_t value;
        RDTPPacketComponent component;
        bool shouldContinue = true;
        while (shouldContinue) {
            switch (RDTPPacket_getReceiveData(&packet, &value, &component)) {
                case DataAvailable:
                    switch (component) {
                    case LeftMotor:
                        motorPower[0] = (uint8_t)value;
                        break;
                    case RightMotor:
                        motorPower[1] = (uint8_t)value;
                        break;
                    case Servo0:
                    {
                        servos[0]->setPosition(value, &error);
                        uint16_t current = servos[0]->current(&error);
                        if (error == Serial::Error::NoError) {
                            if (servo0CurrentAverage.addValue(current) > largeCurrent) {
                                servos[0]->setTorque(false, &error);
                                uint8_t notify = RDTP_TORQUE_DISABLED;
                                udp_client_write(&client, &notify, sizeof(notify));
                            }
                        }
                    }
                        break;
                    case Servo1: case Servo2: case Servo3: case Servo4: 
                    case Servo5: case Servo6: case Servo7: case Servo8: case Servo9:
                        servos[component - Servo0]->setPosition(value, &error);
                        break;
                    case EnableServo:
                        break;
                    case DisableServo:
                        break;
                    default:
                        break;
                }
                break;
                case EndOfPacket:
                    shouldContinue = false;
                    break;
                case CommandAvailable:
                    switch (RDTPPacket_getReceiveCommand(&packet)) {
                        case StartVideo0:
                            if (child) {
                                kill(child, SIGINT);
                            }
                            child = fork();
                            if (child == 0) {
                                /* child */
                                execl("/usr/bin/gst-launch-1.0", "gst-launch-1.0", "v4l2src", frontCameraPath, 
                                      "!", "videoscale", "!", "video/x-raw, width=320, height=240", "!", "jpegenc",
                                      "!", "udpsink", gstreamerAddressString, gstreamerPortString, (char *)NULL);
                                return 0;
                            }
                            break;
                        case StartVideo1:
                            if (child) {
                                kill(child, SIGINT);
                            }
                            child = fork();
                            if (child == 0) {
                                /* child */
                                execl("/usr/bin/gst-launch-1.0", "gst-launch-1.0", "v4l2src", backCameraPath,
                                      "!", "videoscale", "!", "video/x-raw, width=320, height=240", "!", "jpegenc",
                                      "!", "udpsink", gstreamerAddressString, gstreamerPortString, (char *)NULL);
                                return 0;
                            }
                            break;
                        case StopVideo:
                            if (child) {
                                kill(child, SIGINT);
                            }
                            break;
                        case Shutdown:
                            if (child) {
                                kill(child, SIGINT);
                            }
                            for (int i = 0; i < NumOfServo; ++i) {
                                servos[i]->setTorque(false, &error);
                            }
                            ackPacket[0] = RDTP_SHUTDOWN_ACK;
                            udp_client_write(&client, const_cast<uint8_t *>(ackPacket), 1);
                            return 0;
                        case Ping:
                            break;
                        case RebootServo:
                            for (int i = 0; i < NumOfServo; ++i) {
                                servos[i]->rebootIfNeeded(&error);
                                servos[i]->setTorque(true, &error);
                            }
                        {
                            union {
                                struct __attribute__((packed)) {
                                    uint8_t command;
                                    int32_t position;
                                };
                                uint8_t raw[5];
                            } buf;
                            buf.command = RDTP_POS_INFO;
                            buf.position = servos[0]->intPosition(&error);
                            udp_client_write(&client, buf.raw, sizeof(buf));
                        }
                            break;
                        default:
                            break;
                    }
                    shouldContinue = false;
                    break;
                default:
                    break;
            }
        }
        const uint8_t arr[] = {0x80, motorPower[0], motorPower[1]};
        serial.write(arr, sizeof(arr));
    }
    return 0;
}
