#include <opencv/cv.h>
#include <opencv/cxcore.h>
#include <opencv/highgui.h>
#include "UDPClient.h"
#include <stdlib.h>
#include <arpa/inet.h>
#include "motiondetector.h"
#include <pthread.h>

volatile int threashold = 40;
volatile int smallArea = 100;
volatile int largeArea = 500;
volatile bool shouldResetInitialFrame = false;
udp_client_t udp;

void *udpReader(void __attribute__((unused)) *arg)
{
    union {
        struct __attribute__((packed)) {
            int8_t id;
            int32_t value;
        };
        uint8_t raw[5];
    } buf;
    while (1) {
        ssize_t size = udp_client_read(&udp, buf.raw, sizeof(buf));
        if (size == 5) {
            switch (buf.id) {
                case CHANGE_THRES:
                    threashold = buf.value;
                    break;
                case CHANGE_SMALL:
                    smallArea = buf.value;
                    break;
                case CHANGE_LARGE:
                    largeArea = buf.value;
                    break;
                case RESET_INITIAL:
                    shouldResetInitialFrame = true;
                    break;
            }
        }
    }
    return NULL;
}

int main(int argc, const char * argv[])
{
    if (argc < 3) {
        printf("usage: %s <Camera Index> <Destination Address>\n", argv[0]);
        return 1;
    }
    udp_address_t address;
    address.address.sin_family = AF_INET;
    address.address.sin_port = htons(59604);
    address.address.sin_addr.s_addr = inet_addr(argv[2]);
    address.addressLength = sizeof(struct sockaddr_in);
    udp_client_init(&udp, &address);
    pthread_t thread;
    pthread_create(&thread, NULL, udpReader, NULL);
    cv::Mat initialFrame;
    cv::VideoCapture capture(atoi(argv[1]));
    while (1) {
        cv::Mat frame;
        capture.read(frame);
        cv::Mat gray;
        cv::cvtColor(frame, gray, cv::COLOR_BGR2GRAY);
        cv::GaussianBlur(gray, gray, cv::Size(21, 21), 0);
        
        if (initialFrame.empty()) {
            gray.copyTo(initialFrame);
            continue;
        }
        
        cv::Mat frameDelta;
        cv::absdiff(initialFrame, gray, frameDelta);
        cv::Mat thresh;
        cv::threshold(frameDelta, thresh, threashold, 255, cv::THRESH_BINARY);
        
        cv::dilate(thresh, thresh, cv::Mat(), cv::Point(-1, -1), 2);
        cv::Mat threshCopy = thresh;
        std::vector<std::vector<cv::Point>> conts;
        cv::findContours(threshCopy, conts, cv::RETR_EXTERNAL, cv::CHAIN_APPROX_SIMPLE);
        
        cv::Mat frameWithRect = frame;
        for (auto &&c : conts) {
            if (cv::contourArea(c) < smallArea || cv::contourArea(c) > largeArea) {
                continue;
            }
            cv::Rect rect = cv::boundingRect(c);
            cv::rectangle(frameWithRect, cv::Point(rect.x, rect.y),
                          cv::Point(rect.x + rect.width, rect.y + rect.height),
                          cv::Scalar(0, 255, 255), 2);
        }
        std::vector<uchar> buf;
        cv::resize(frameWithRect, frameWithRect, cv::Size(), 0.5, 0.5);
        cv::imencode(".jpg", frameWithRect, buf);
        udp_client_write(&udp, buf.data(), buf.size());

        if (shouldResetInitialFrame) {
            initialFrame = gray;
        }
    }
    return 0;
}
