#import <Cocoa/Cocoa.h>
#import "GCDAsyncUDPSocket.h"
#import "RDTPPacket.h"

@class RDTP;

@protocol RDTPDelegate <NSObject>

@required
- (void)RDTP:(RDTP *)app videoFrameAvailable:(NSData *)jpg;
- (void)RDTP:(RDTP *)app willSendPacket:(RDTPPacket *)packet;
- (void)RDTPDidFoundRobot:(RDTP *)app withInitialServoPositions:(int32_t *)positions;
- (void)RDTP:(RDTP *)app didReceivePositionInformation:(int32_t)position;
- (void)RDTP:(RDTP *)app didUpdateBatteryVolatage:(float)percentage;
- (void)RDTPDidDisableServo:(RDTP *)app;

@end

@interface RDTP : NSObject <GCDAsyncUdpSocketDelegate>

@property NSObject<RDTPDelegate> *delegate;
- (void)shutdown;
- (RDTPPacket *)packet;

@end
