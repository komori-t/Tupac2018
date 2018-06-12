#include "UDPServer.h"
#include "RDTPPacket.h"
#include "Serial.hpp"
#include "Dynamixel.hpp"
#include <signal.h>
#include <unistd.h>

int main()
{
    udp_server_t server;
    udp_server_init(&server, RDTP_PORT);
    RDTPPacket packet;
    RDTPPacketBuffer buffer;
    uint8_t motorPower[3] = {128, 0, 0};
    bool success;
    Serial serial("/dev/ttyTHS2", B9600, success);
    Serial servoSerial("/dev/ttyUSB0", B115200, success);
    Dynamixel<1> servo0(&servoSerial);
    Dynamixel<2> servo1(&servoSerial);
    Dynamixel<3> servo2(&servoSerial);
    Serial::Error error;
    servo0.setTorque(true, &error);
    servo1.setTorque(true, &error);
    servo2.setTorque(true, &error);
    pid_t child = 0;
    if (error != Serial::Error::NoError) return (int)error;
    while (1) {
        ssize_t length = udp_server_read(&server, (uint8_t *)buffer.buffer, sizeof(buffer));
        RDTPPacket_initWithBytes(&packet, buffer.buffer, length);
        int8_t value;
        RDTPPacketComponent component;
        bool shouldContinue = true;
        while (shouldContinue) {
            switch (RDTPPacket_getReceiveData(&packet, &value, &component)) {
                case DataAvailable:
                    switch (component) {
                    case LeftMotor:
                        motorPower[1] = (uint8_t)value;
                        break;
                    case RightMotor:
                        motorPower[2] = (uint8_t)value;
                        break;
                    case Servo0:
                    {
                        double pos = 360.0 * value / 128;
                        servo0.setPosition(pos, &error);
                        break;
                    }
                    case Servo1:
                    {
                        double pos = 360.0 * value / 128;
                        servo1.setPosition(pos, &error);
                        break;
                    }
                    case Servo2:
                    {
                        double pos = 360.0 * value / 128;
                        servo2.setPosition(pos, &error);
                        break;
                    }
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
                                execl("/usr/bin/gst-launch-1.0", "gst-launch-1.0", "v4l2src", "device=/dev/video0", "!", "videoscale", "!", "video/x-raw, width=320, height=240", "!", "jpegenc", "!", "udpsink", "host=192.168.11.3", "port=49153", (char *)NULL);
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
                                execl("/usr/bin/gst-launch-1.0", "gst-launch-1.0", "v4l2src", "device=/dev/video1", "!", "videoscale", "!", "video/x-raw, width=320, height=240", "!", "jpegenc", "!", "udpsink", "host=192.168.11.3", "port=49153", (char *)NULL);
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
                            servo0.setTorque(false, &error);
                            servo1.setTorque(false, &error);
                            servo2.setTorque(false, &error);
                            return 0;
                        default:
                            break;
                    }
                    shouldContinue = false;
                    break;
                default:
                    break;
            }
        }
        std::array<uint8_t, 3> arr({128, motorPower[1], motorPower[2]});
        serial.transfer(arr);
    }
    return 0;
}