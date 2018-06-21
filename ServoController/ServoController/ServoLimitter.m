#import "ServoLimitter.h"

@implementation ServoLimitter
{
    int32_t stepValue;
    RDTPPacket *packet;
    RDTPPacketComponent servo;
    BOOL shouldPreset;
    int32_t presetGoal;
}

- (instancetype)initWithServo:(RDTPPacketComponent)aServo packet:(RDTPPacket *)aPacket
{
    if (self = [super init]) {
        packet = aPacket;
        servo = aServo;
        shouldPreset = NO;
        self.currentValue = 0;
        stepValue = 0;
        self.shouldInvert = NO;
//        self.upperLimit = 60;
//        self.lowerLimit = -60;
        self.upperLimit = INT_MAX;
        self.lowerLimit = INT_MIN;
        self.divScale = 1;
    }
    
    return self;
}

- (void)updateStep:(int)step
{
    stepValue = (self.shouldInvert ? -step : step) / 5000 / self.divScale;
}

- (BOOL)update
{
    BOOL ret = YES;
    if (shouldPreset) {
        if (abs(self.currentValue - presetGoal) < abs(stepValue)) {
            self.currentValue = presetGoal;
            stepValue = 0;
            shouldPreset = NO;
            ret = NO;
        } else {
            self.currentValue += stepValue;
        }
        RDTPPacket_updateValue(packet, servo, self.currentValue);
    } else if (stepValue) {
        self.currentValue += stepValue;
        if (stepValue > 0) {
            if (self.currentValue > self.upperLimit) {
                stepValue = 0;
                self.currentValue = self.upperLimit;
                ret = NO;
            }
        } else if (self.currentValue < self.lowerLimit) {
            stepValue = 0;
            self.currentValue = self.lowerLimit;
            ret = NO;
        }
        RDTPPacket_updateValue(packet, servo, self.currentValue);
    } else {
        ret = NO;
    }
    return ret;
}

- (void)presetToAngle:(int32_t)angle
{
    shouldPreset = YES;
    presetGoal = angle;
    if (self.currentValue > angle) {
        stepValue = -20 / self.divScale;
    } else {
        stepValue = 20 / self.divScale;
    }
}

@end
