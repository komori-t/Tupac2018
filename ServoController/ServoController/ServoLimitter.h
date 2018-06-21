#import <Foundation/Foundation.h>
#import "RDTPPacket.h"

@interface ServoLimitter : NSObject

@property BOOL shouldInvert;
@property int32_t upperLimit;
@property int32_t lowerLimit;
@property int32_t currentValue;
@property double divScale;

- (instancetype)initWithServo:(RDTPPacketComponent)servo packet:(RDTPPacket *)aPacket;
- (void)updateStep:(int)step;
- (BOOL)update;
- (void)presetToAngle:(int32_t)angle;

@end
