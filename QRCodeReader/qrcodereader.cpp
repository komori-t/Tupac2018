#include <stdlib.h>
#include <zbar.h>
#include <opencv/cv.h>
#include <opencv/cxcore.h>
#include <opencv/highgui.h>
#include "UDPClient.h"
#include <arpa/inet.h>

int main(int argc, const char *argv[])
{
    if (argc < 3) {
        printf("Usage: %s <Camera Index> <Destination Address>\n", argv[0]);
        return 1;
    }
    udp_client_t udp;
    udp_address_t address;
    address.address.sin_family = AF_INET;
    address.address.sin_port = htons(59604);
    address.address.sin_addr.s_addr = inet_addr(argv[2]);
    address.addressLength = sizeof(struct sockaddr_in);
    udp_client_init(&udp, &address);
    zbar::ImageScanner scanner;
    scanner.set_config(zbar::ZBAR_NONE, zbar::ZBAR_CFG_ENABLE, 1);
    cv::VideoCapture capture(atoi(argv[1]));
    while (1) {
        cv::Mat frame;
        capture.read(frame);
        cv::Mat gray;
        cv::cvtColor(frame, gray, cv::COLOR_BGR2GRAY);
        int width  = gray.cols;
        int height = gray.rows;
        zbar::Image image(width, height, "Y800", gray.data, gray.elemSize() * gray.total());
        int status = scanner.scan(image);
        if (status < 0) {
            printf("scan error\n");
        }
        std::vector<cv::Point> vp;
        for (zbar::Image::SymbolIterator symbol = image.symbol_begin();
             symbol != image.symbol_end();
             ++symbol) {
            printf("%s\n", symbol->get_data().c_str());
            for (int i = 0; i < symbol->get_location_size(); ++i) {
                vp.push_back(cv::Point(symbol->get_location_x(i), symbol->get_location_y(i)));
            }
        }
        if (vp.size()) {
            cv::RotatedRect r = cv::minAreaRect(vp);
            cv::Point2f pts[4];
            r.points(pts);
            for (int i = 0; i < 4; ++i){
                line(frame, pts[i], pts[(i+1)%4], cvScalar(255, 0, 0), 3);
            }
        }
        // cv::imshow("frame", frame);
        std::vector<uchar> buf;
        cv::resize(frame, frame, cv::Size(), 0.5, 0.5);
        cv::imencode(".jpg", frame, buf);
        udp_client_write(&udp, buf.data(), buf.size());
        // if (cv::waitKey(1) == 'q') {
        //     break;
        // }
    }
    return 0;
}