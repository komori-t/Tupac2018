#include <opencv/cv.hpp>
#include <stdlib.h>

int main(int argc, const char * argv[])
{
    cv::Mat frame = cv::imread("IMG_2174.JPG");
    
    int width = frame.cols / 2;
    int height = frame.rows / 2;
    cv::Mat hazmats[4];
    cv::Mat rot;

    hazmats[0] = cv::Mat(frame, cv::Rect(0, 0, width, height));
    rot = cv::getRotationMatrix2D(cv::Point2f(width / 2, height / 2), 135, 1);
    cv::warpAffine(hazmats[0], hazmats[0], rot, cv::Size(width, height));

    hazmats[1] = cv::Mat(frame, cv::Rect(0, height, width, height));
    rot = cv::getRotationMatrix2D(cv::Point2f(width / 2, height / 2), 45, 1);
    cv::warpAffine(hazmats[1], hazmats[1], rot, cv::Size(width, height));

    hazmats[2] = cv::Mat(frame, cv::Rect(width, 0, width, height));
    rot = cv::getRotationMatrix2D(cv::Point2f(width / 2, height / 2), 225, 1);
    cv::warpAffine(hazmats[2], hazmats[2], rot, cv::Size(width, height));

    hazmats[3] = cv::Mat(frame, cv::Rect(width, height, width, height));
    rot = cv::getRotationMatrix2D(cv::Point2f(width / 2, height / 2), -45, 1);
    cv::warpAffine(hazmats[3], hazmats[3], rot, cv::Size(width, height));

    cv::Mat upside;
    cv::Mat downside;
    cv::Mat whole;

    for (auto &&hazmat : hazmats) {
        cv::imwrite("image.png", hazmat);
        FILE *ruby = popen("ruby hazmat.rb image.png", "r");
        char buf[256];
        fgets(buf, sizeof(buf), ruby);
        printf("%s", buf);
        std::vector<cv::Point> vp;
        char c = 0;
        for (int i = 0; c != EOF; ++i) {
            int x = 0;
            int y = 0;
            for (int j = 0; j < sizeof(buf); ++j) {
                c = fgetc(ruby);
                putchar(c);
                if (c == EOF) break;
                if (c == ',') {
                    buf[j] = '\0';
                    x = atoi(buf);
                    break;
                } else {
                    buf[j] = c;
                }
            }
            if (c == EOF) break;
            for (int j = 0; j < sizeof(buf); ++j) {
                c = fgetc(ruby);
                putchar(c);
                if (c == EOF) break;
                if (c == ',') {
                    buf[j] = '\0';
                    y = atoi(buf);
                    break;
                } else {
                    buf[j] = c;
                }
            }
            vp.push_back(cv::Point(x, y));
        }
        pclose(ruby);
        cv::RotatedRect r = cv::minAreaRect(vp);
        cv::Point2f pts[4];
        r.points(pts);
        for (int i = 0; i < 4; ++i){
            cv::line(hazmat, pts[i], pts[(i+1)%4], cv::Scalar(255, 0, 0), 3);
        }
    }

    cv::hconcat(&hazmats[0], 2, upside);
    cv::hconcat(&hazmats[2], 2, downside);
    cv::Mat parts[] = {upside, downside};
    cv::vconcat(parts, 2, whole);
    cv::resize(whole, whole, cv::Size(), 0.3, 0.3);
    cv::imshow("window", whole);

    while (1) {
        if (cv::waitKey(1) == 'q') {
            break;
        }
    }
    
    cv::VideoCapture cap(0);
    while (1) {
        cv::Mat frame;
        cap.read(frame);
        cv::line(frame, cv::Point(0, frame.rows / 2), cv::Point(frame.cols, frame.rows / 2), cvScalar(255, 0, 0), 3);
        cv::line(frame, cv::Point(frame.cols / 2, 0), cv::Point(frame.cols / 2, frame.rows), cvScalar(255, 0, 0), 3);
        cv::imshow("window", frame);
        if (cv::waitKey(1) == 'q') {
            break;
        }
    }
    
    return 0;
}
