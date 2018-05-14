#import <Foundation/Foundation.h>
#import "RDTPPacket.h"

@interface ServoLimitter : NSObject

@property BOOL shouldInvert;
@property int upperLimit;
@property int lowerLimit;
@property int currentValue;

- (instancetype)initWithServo:(RDTPPacketComponent)servo packet:(RDTPPacket *)aPacket;
- (void)updateStep:(int)step;
- (BOOL)update;
- (void)preset;

@end
