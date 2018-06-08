#import <Foundation/Foundation.h>
#import "RDTPPacket.h"
#import "GamepadController.h"

@interface StickConverter : NSObject<GamepadDelegate>

@property BOOL shouldFlip;

- (instancetype)initWithRDTPPacket:(RDTPPacket *)packet;
- (NSData *)makePacketData;

@end
