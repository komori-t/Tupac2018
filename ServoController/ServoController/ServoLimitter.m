#import "ServoLimitter.h"

@implementation ServoLimitter
{
    int stepValue;
    RDTPPacket *packet;
    RDTPPacketComponent servo;
    BOOL shouldPreset;
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
        self.upperLimit = 60;
        self.lowerLimit = -60;
    }
    
    return self;
}

- (void)updateStep:(int)step
{
    stepValue = (self.shouldInvert ? -step : step) / 50;
}

- (BOOL)update
{
    BOOL ret = YES;
    if (shouldPreset) {
        if (abs(self.currentValue) < abs(stepValue)) {
            self.currentValue = 0;
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
    }
    return ret;
}

- (void)preset
{
    shouldPreset = YES;
    if (self.currentValue > 0) {
        stepValue = -5;
    } else {
        stepValue = 5;
    }
}

@end
