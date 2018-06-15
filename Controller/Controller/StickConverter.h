#import <Foundation/Foundation.h>
#import "RDTPPacket.h"
#import "GamepadController.h"

@interface StickConverter : NSObject<GamepadDelegate>

@property BOOL shouldFlip;

- (instancetype)initWithRDTPPacket:(RDTPPacket *)packet initialFlipperPositions:(int32_t *)positions;
- (void)updatePacket;

@end
