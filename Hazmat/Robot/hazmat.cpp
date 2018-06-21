#include <opencv/cv.h>
#include <opencv/cxcore.h>
#include <opencv/highgui.h>
#include "UDPServer.h"
#include "UDPClient.h"
#include "hazmat.h"
#include <arpa/inet.h>
#include <pthread.h>

static volatile bool ready = false;
static udp_server_t server;
static udp_client_t client;
static volatile double widthPercentage = 0;
static volatile double heightPercentage = 0;

void *commandReader(void __attribute__((unused)) *arg)
{
    uint8_t buf[sizeof(uint8_t) + 2 * sizeof(double)];
    while (1) {
        ssize_t len = udp_server_read(&server, buf, sizeof(buf));
        if (len == 1) {
            ready = true;
        } else if (len == sizeof(uint8_t) + 2 * sizeof(double)) {
            double value;
            memcpy(&value, &buf[1], sizeof(value));
            widthPercentage = value;
            memcpy(&value, &buf[1 + sizeof(value)], sizeof(value));
            heightPercentage = value;
        }
    }
    return NULL;
}

int main(int argc, const char *argv[])
{
    if (argc < 2) {
        printf("Usage: %s <Camera Index>\n", argv[0]);
        return 1;
    }
    cv::VideoCapture capture(atoi(argv[1]));
    udp_server_init(&server, 59604);
    udp_address_t address;
    uint8_t buf;
    while (1) {
        udp_server_readFrom(&server, &buf, 1, &address);
        if (buf == HAZMAT_START) break;
    }
    puts("start");
    udp_server_connect(&server, &address);
    address.address.sin_port = htons(59605);
    udp_client_init(&client, &address);
    pthread_t thread;
    pthread_create(&thread, NULL, commandReader, &address);
    while (1) {
        cv::Mat frame;
        capture.read(frame);
        int width = frame.cols;
        int height = frame.rows;
        frame = cv::Mat(frame, cv::Rect(widthPercentage, heightPercentage, width - 2 * widthPercentage, height - 2 * heightPercentage));
        if (ready) {
            ready = false;
            puts("detecting");

            int width = frame.cols;
            int height = frame.rows;
            cv::Mat rot;
            rot = cv::getRotationMatrix2D(cv::Point2f(width / 2, height / 2), 225, 1);
            cv::warpAffine(frame, frame, rot, cv::Size(width, height));
            cv::imwrite("image.png", frame);
            system("ruby hazmat.rb image.png");
            // FILE *ruby = popen("ruby hazmat.rb image.png", "r");
            // char buf[256];
            // fgets(buf, sizeof(buf), ruby);
            // printf("%s", buf);
            // std::vector<cv::Point> vp;
            // int c = 0;
            // for (int i = 0; c != EOF && ! feof(ruby); ++i) {
            //     int x = 0;
            //     int y = 0;
            //     for (unsigned int j = 0; j < sizeof(buf); ++j) {
            //         c = fgetc(ruby);
            //         // putchar(c);
            //         if (c == EOF) break;
            //         if (c == ',') {
            //             buf[j] = '\0';
            //             x = atoi(buf);
            //             break;
            //         } else {
            //             buf[j] = c;
            //         }
            //     }
            //     if (c == EOF) break;
            //     for (unsigned int j = 0; j < sizeof(buf); ++j) {
            //         c = fgetc(ruby);
            //         // putchar(c);
            //         if (c == EOF) break;
            //         if (c == ',') {
            //             buf[j] = '\0';
            //             y = atoi(buf);
            //             break;
            //         } else {
            //             buf[j] = c;
            //         }
            //     }
            //     vp.push_back(cv::Point(x, y));
            // }
            // pclose(ruby);
            // if (vp.size() >= 2) {
            //     cv::RotatedRect r = cv::minAreaRect(vp);
            //     cv::Point2f pts[4];
            //     r.points(pts);
            //     for (int i = 0; i < 4; ++i){
            //         cv::line(frame, pts[i], pts[(i+1)%4], cv::Scalar(255, 0, 0), 3);
            //     }
            // }
            // std::vector<uchar> buffer;
            // cv::resize(frame, frame, cv::Size(), 0.5, 0.5);
            // cv::imencode(".jpg", frame, buffer);
            // udp_client_write(&client, buffer.data(), buffer.size());

            // int width = frame.cols;
            // int height = frame.rows;
            // cv::Mat hazmats[4];
            // cv::Mat rot;
            
            // // hazmats[0] = cv::Mat(frame, cv::Rect(0, 0, width / 2, height / 2));
            // // rot = cv::getRotationMatrix2D(cv::Point2f(width / 4, height / 4), 135, 1);
            // // cv::warpAffine(hazmats[0], hazmats[0], rot, cv::Size(width, height));
            
            // // hazmats[1] = cv::Mat(frame, cv::Rect(0, height / 2, width / 2, height / 2));
            // // rot = cv::getRotationMatrix2D(cv::Point2f(width / 4, height / 4), 45, 1);
            // // cv::warpAffine(hazmats[1], hazmats[1], rot, cv::Size(width, height));

            // // hazmats[2] = cv::Mat(frame, cv::Rect(width / 2, 0, width / 2, height / 2));
            // // rot = cv::getRotationMatrix2D(cv::Point2f(width / 4, height / 4), 225, 1);
            // // cv::warpAffine(hazmats[2], hazmats[2], rot, cv::Size(width, height));

            // // hazmats[3] = cv::Mat(frame, cv::Rect(width / 2, height / 2, width / 2, height / 2));
            // // rot = cv::getRotationMatrix2D(cv::Point2f(width / 4, height / 4), -45, 1);
            // // cv::warpAffine(hazmats[3], hazmats[3], rot, cv::Size(width, height));
            // hazmats[0] = cv::Mat(frame, cv::Rect(0, 0, width / 2, height / 2));
            // rot = cv::getRotationMatrix2D(cv::Point2f(width / 4, height / 4), 225, 1);
            // cv::warpAffine(hazmats[0], hazmats[0], rot, cv::Size(width, height));
            
            // hazmats[1] = cv::Mat(frame, cv::Rect(0, height / 2, width / 2, height / 2));
            // rot = cv::getRotationMatrix2D(cv::Point2f(width / 4, height / 4), 225, 1);
            // cv::warpAffine(hazmats[1], hazmats[1], rot, cv::Size(width, height));

            // hazmats[2] = cv::Mat(frame, cv::Rect(width / 2, 0, width / 2, height / 2));
            // rot = cv::getRotationMatrix2D(cv::Point2f(width / 4, height / 4), 225, 1);
            // cv::warpAffine(hazmats[2], hazmats[2], rot, cv::Size(width, height));

            // hazmats[3] = cv::Mat(frame, cv::Rect(width / 2, height / 2, width / 2, height / 2));
            // rot = cv::getRotationMatrix2D(cv::Point2f(width / 4, height / 4), 225, 1);
            // cv::warpAffine(hazmats[3], hazmats[3], rot, cv::Size(width, height));
            
            // cv::Mat upside;
            // cv::Mat downside;
            // cv::Mat whole;
            
            // for (auto &&hazmat : hazmats) {
            //     cv::imwrite("image.png", hazmat);
            //     FILE *ruby = popen("ruby hazmat.rb image.png", "r");
            //     char buf[256];
            //     fgets(buf, sizeof(buf), ruby);
            //     printf("%s", buf);
            //     std::vector<cv::Point> vp;
            //     int c = 0;
            //     for (int i = 0; c != EOF && ! feof(ruby); ++i) {
            //         int x = 0;
            //         int y = 0;
            //         for (unsigned int j = 0; j < sizeof(buf); ++j) {
            //             c = fgetc(ruby);
            //             // putchar(c);
            //             if (c == EOF) break;
            //             if (c == ',') {
            //                 buf[j] = '\0';
            //                 x = atoi(buf);
            //                 break;
            //             } else {
            //                 buf[j] = c;
            //             }
            //         }
            //         if (c == EOF) break;
            //         for (unsigned int j = 0; j < sizeof(buf); ++j) {
            //             c = fgetc(ruby);
            //             // putchar(c);
            //             if (c == EOF) break;
            //             if (c == ',') {
            //                 buf[j] = '\0';
            //                 y = atoi(buf);
            //                 break;
            //             } else {
            //                 buf[j] = c;
            //             }
            //         }
            //         vp.push_back(cv::Point(x, y));
            //     }
            //     pclose(ruby);
            //     if (vp.size() >= 2) {
            //         cv::RotatedRect r = cv::minAreaRect(vp);
            //         cv::Point2f pts[4];
            //         r.points(pts);
            //         for (int i = 0; i < 4; ++i){
            //             cv::line(hazmat, pts[i], pts[(i+1)%4], cv::Scalar(255, 0, 0), 3);
            //         }
            //     }
            // }
            
            // cv::hconcat(&hazmats[0], 2, upside);
            // cv::hconcat(&hazmats[2], 2, downside);
            // cv::Mat parts[] = {upside, downside};
            // cv::vconcat(parts, 2, whole);
            // // cv::resize(whole, whole, cv::Size(), 0.5, 0.5);
            // std::vector<uchar> buf;
            // cv::imencode(".jpg", whole, buf);
            // udp_client_write(&client, buf.data(), buf.size());
        }
        // cv::line(frame, cv::Point(0, frame.rows / 2), cv::Point(frame.cols, frame.rows / 2), cvScalar(255, 0, 0), 3);
        // cv::line(frame, cv::Point(frame.cols / 2, 0), cv::Point(frame.cols / 2, frame.rows), cvScalar(255, 0, 0), 3);
        cv::resize(frame, frame, cv::Size(), 0.5, 0.5);
        std::vector<uchar> buf;
        cv::imencode(".jpg", frame, buf);
        udp_server_write(&server, buf.data(), buf.size());
    }
    
    return 0;
}
