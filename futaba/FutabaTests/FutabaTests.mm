#import <XCTest/XCTest.h>
#import "futaba.hpp"

class FutabaDelegate : public Futaba::Delegate {
    uint8_t *count;
    uint8_t *buf;
    void futaba_send(Futaba *servo, uint8_t cnt, uint8_t data[cnt]) {
        *count = cnt;
        memcpy(buf, data, cnt);
    }
public:
    FutabaDelegate(uint8_t *_count, uint8_t *_buf) : count(_count), buf(_buf) {
        
    }
};

@interface FutabaTests : XCTestCase

@end

@implementation FutabaTests

- (void)testSetPosition
{
    const uint8_t ID = 1;
    uint8_t count;
    uint8_t buf[32];
    FutabaDelegate delegate = FutabaDelegate(&count, buf);
    Futaba servo = Futaba(&delegate, ID);
    servo.setGoalPosition(0);
    XCTAssertEqual(count, 10);
    XCTAssertEqual(buf[0], 0xFA);
    XCTAssertEqual(buf[1], 0xAF);
    XCTAssertEqual(buf[2], ID);
    XCTAssertEqual(buf[3], 0);
    XCTAssertEqual(buf[4], 0x1E);
    XCTAssertEqual(buf[5], 2);
    XCTAssertEqual(buf[6], 1);
    XCTAssertEqual(buf[7], 0);
    XCTAssertEqual(buf[8], 0);
    XCTAssertEqual(buf[9], 0x1C);
}

@end
