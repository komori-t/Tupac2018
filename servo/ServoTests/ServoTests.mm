#import <XCTest/XCTest.h>
#include "Dynamixel.hpp"
#include "Futaba.hpp"

static NSData *writeData;
static NSData *readData;

extern "C" {
    ssize_t write(int fd, const void *buf, size_t count);
    ssize_t read(int fd, void *buf, size_t count);
    ssize_t readv(int fd, const struct iovec *iov, int iovcnt);
    ssize_t writev(int fd, const struct iovec *iov, int iovcnt);
}

ssize_t write(int fd, const void *buf, size_t count)
{
    writeData = [NSData dataWithBytes:buf length:count];
    return count;
}

ssize_t read(int fd, void *buf, size_t count)
{
    if (readData) {
        assert(count == [readData length]);
        [readData getBytes:buf length:count];
        return count;
    } else {
        return 0;
    }
}

ssize_t readv(int fd, const struct iovec *iov, int iovcnt)
{
    abort();
}

ssize_t writev(int fd, const struct iovec *iov, int iovcnt)
{
    NSMutableData *data = [NSMutableData new];
    for (int i = 0; i < iovcnt; ++i) {
        [data appendBytes:iov[i].iov_base length:iov[i].iov_len];
    }
    writeData = data;
    return [data length];
}

@interface ServoTests : XCTestCase

@end

@implementation ServoTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testServo
{
    bool success;
    Serial::Error error;
    Serial serial("", 9600, success);
    Dynamixel<1> dynamixel(&serial);
    Futaba<1> futaba(&serial);
    {
        uint8_t writeBuf[] = {0xFF, 0xFF, 0xFD, 0x00, 1, 7, 0, 2, 0x84, 0, 4, 0, 0x1D, 0x15};
        uint8_t readBuf[] = {0xFF, 0xFF, 0xFD, 0x00, 1, 8, 0, 0x55, 0, 0x5D, 0x0E, 0x00, 0x00, 0x7C, 0x9C};
        readData = [NSData dataWithBytes:readBuf length:sizeof(readBuf)];
        int32_t pos = dynamixel.intPosition(&error);
        XCTAssertEqualObjects(writeData, [NSData dataWithBytes:writeBuf length:sizeof(writeBuf)]);
        XCTAssertEqual(pos, 3677);
        XCTAssertEqual(error, Serial::Error::NoError);
    }
    {
        uint8_t writeBuf[] = {0xFF, 0xFF, 0xFD, 0x00, 1, 9, 0, 3, 0x74, 0, 0xE7, 0x03, 0, 0, 0xF0, 0x65};
        uint8_t readBuf[] = {0xFF, 0xFF, 0xFD, 0x00, 1, 4, 0, 0x55, 0, 0xA1, 0x0C};
        readData = [NSData dataWithBytes:readBuf length:sizeof(readBuf)];
        dynamixel.setPosition(999, &error);
        XCTAssertEqualObjects(writeData, [NSData dataWithBytes:writeBuf length:sizeof(writeBuf)]);
        XCTAssertEqual(error, Serial::Error::NoError);
    }
    {
        uint8_t writeBuf[] = {0xFA, 0xAF, 1, 0, 0x1E, 2, 1, 0, 0, 0x1C};
        futaba.setPosition(static_cast<int16_t>(0), &error);
        XCTAssertEqualObjects(writeData, [NSData dataWithBytes:writeBuf length:sizeof(writeBuf)]);
        XCTAssertEqual(error, Serial::Error::NoError);
    }
    {
        uint8_t writeBuf[] = {0xFA, 0xAF, 1, 0, 0x1E, 2, 1, 0x84, 0x03, 0x9B};
        futaba.setPosition(static_cast<int16_t>(900), &error);
        XCTAssertEqualObjects(writeData, [NSData dataWithBytes:writeBuf length:sizeof(writeBuf)]);
        XCTAssertEqual(error, Serial::Error::NoError);
    }
    {
        uint8_t writeBuf[] = {0xFA, 0xAF, 1, 0, 0x1E, 2, 1, 0x7C, 0xFC, 0x9C};
        futaba.setPosition(static_cast<int16_t>(-900), &error);
        XCTAssertEqualObjects(writeData, [NSData dataWithBytes:writeBuf length:sizeof(writeBuf)]);
        XCTAssertEqual(error, Serial::Error::NoError);
    }
    {
        uint8_t writeBuf[] = {0xFA, 0xAF, 1, 0, 0x24, 1, 1, 1, 0x24};
        futaba.setTorque(true, &error);
        XCTAssertEqualObjects(writeData, [NSData dataWithBytes:writeBuf length:sizeof(writeBuf)]);
        XCTAssertEqual(error, Serial::Error::NoError);
    }
    {
        uint8_t writeBuf[] = {0xFA, 0xAF, 1, 0, 0x24, 1, 1, 0, 0x25};
        futaba.setTorque(false, &error);
        XCTAssertEqualObjects(writeData, [NSData dataWithBytes:writeBuf length:sizeof(writeBuf)]);
        XCTAssertEqual(error, Serial::Error::NoError);
    }
    {
        uint8_t writeBuf[] = {0xFA, 0xAF, 1, 0x0F, 0x2A, 2, 0, 0x26};
        uint8_t readBuf[] = {0xFD, 0xDF, 1, 0, 0x2A, 2, 1, 0x84, 0x03, 0xAF};
        readData = [NSData dataWithBytes:readBuf length:sizeof(readBuf)];
        int16_t pos = futaba.intPosition(&error);
        XCTAssertEqualObjects(writeData, [NSData dataWithBytes:writeBuf length:sizeof(writeBuf)]);
        XCTAssertEqual(error, Serial::Error::NoError);
        XCTAssertEqual(pos, 900);
    }
    {
        uint8_t writeBuf[] = {0xFA, 0xAF, 1, 0x0F, 0x2A, 2, 0, 0x26};
        readData = nil;
        futaba.intPosition(&error);
        XCTAssertEqualObjects(writeData, [NSData dataWithBytes:writeBuf length:sizeof(writeBuf)]);
        XCTAssertEqual(error, Serial::Error::ReadTimeout);
    }
}

@end
