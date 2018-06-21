#import <Foundation/Foundation.h>
#import "RDTPPacket.h"
#import "GamepadController.h"

@interface StickConverter : NSObject<GamepadDelegate>

@property BOOL shouldFlip;

- (instancetype)initWithRDTPPacket:(RDTPPacket *)packet initialFlipperPositions:(int32_t *)positions;
- (void)updatePacket;
- (void)frontPreset;
- (void)backPreset;
- (void)resetPositionInformation:(int32_t)position forServo:(RDTPPacketComponent)servo;

@end
