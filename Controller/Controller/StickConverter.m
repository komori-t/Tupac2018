#import "StickConverter.h"
#import "GamepadController.h"
#import "ServoLimitter.h"

#define scale(val, sourceMax, destMax) ((destMax) * (val) / (sourceMax))
static const int MediumMaxPower = 76;
static const int BurstMaxPower = 127;
static const int SmallMaxPower = 38;

@implementation StickConverter
{
    int lastLeftXValue;
    int max;
    RDTPPacket *packet;
    int maxPower;
    NSArray<ServoLimitter *> *limitters;
    RDTPPacketComponent servo;
}

- (instancetype)initWithRDTPPacket:(RDTPPacket *)aPacket
{
    if (self = [super init]) {
        lastLeftXValue = 0;
        max = 0;
        maxPower = MediumMaxPower;
        packet = aPacket;
        self.shouldFlip = NO;
        servo = 0;
        
        NSMutableArray<ServoLimitter *> *mutableLimitters = [NSMutableArray new];
        for (RDTPPacketComponent i = Servo0; i <= Servo9; ++i) {
            [mutableLimitters addObject:[[ServoLimitter alloc] initWithServo:i packet:packet]];
        }
        limitters = mutableLimitters;
    }
    return self;
}

- (void)gamepad:(GamepadController *)gamepad updateValue:(int)value forStickAxis:(GamepadStickAxis)stick
{
    switch (stick) {
        case XButton:
            if (value) {
                servo |= 1 << Servo0;
            } else {
                servo &= ~(1 << Servo0);
                [limitters[0] updateStep:0];
            }
            return;
            
        case YButton:
            if (value) {
                servo |= 1 << Servo1;
            } else {
                servo &= ~(1 << Servo1);
                [limitters[1] updateStep:0];
            }
            return;
            
        case AButton:
            if (value) {
                servo |= 1 << Servo2;
            } else {
                servo &= ~(1 << Servo2);
                [limitters[2] updateStep:0];
            }
            return;
            
        case BButton:
            if (value) {
                servo |= 1 << Servo3;
            } else {
                servo &= ~(1 << Servo3);
                [limitters[3] updateStep:0];
            }
            return;
            
        case LeftStickY:
        {
            int8_t angle = scale(value, GAMEPAD_MAX, INT8_MAX);
            const RDTPPacketComponent servos[] = {Servo0, Servo1, Servo2, Servo3};
            for (int i = 0; i < sizeof(servos) / sizeof(servos[0]); ++i) {
                if (servo & (1 << servos[i])) {
                    [limitters[servos[i] - Servo0] updateStep:angle];
                }
            }
            return;
        }
            
        case LeftTrigger:
            if (self.shouldFlip) {
                max = (maxPower * (value + GAMEPAD_MAX)) / (2 * GAMEPAD_MAX);
            } else {
                max = (-maxPower * (value + GAMEPAD_MAX)) / (2 * GAMEPAD_MAX);
            }
            break;
            
        case RightTrigger:
            if (self.shouldFlip) {
                max = (-maxPower * (value + GAMEPAD_MAX)) / (2 * GAMEPAD_MAX);
            } else {
                max = (maxPower * (value + GAMEPAD_MAX)) / (2 * GAMEPAD_MAX);
            }
            break;
            
        case LeftStickX:
            if (self.shouldFlip) {
                lastLeftXValue = -value;
            } else {
                lastLeftXValue = value;
            }
            break;
            
        case RightTriggerButton:
//        case LeftTriggerButton:
            if (! self.shouldFlip) {
                if (value) {
                    RDTPPacket_updateValue(packet, LeftMotor, maxPower);
                    RDTPPacket_updateValue(packet, RightMotor, -maxPower);
                } else {
                    RDTPPacket_updateValue(packet, LeftMotor, 0);
                    RDTPPacket_updateValue(packet, RightMotor, 0);
                }
            } else if (value) {
                RDTPPacket_updateValue(packet, LeftMotor, -maxPower);
                RDTPPacket_updateValue(packet, RightMotor, maxPower);
            } else {
                RDTPPacket_updateValue(packet, LeftMotor, 0);
                RDTPPacket_updateValue(packet, RightMotor, 0);
            }
            return;
            
        case LeftTriggerButton:
//        case RightTriggerButton:
            if (! self.shouldFlip) {
                if (value) {
                    RDTPPacket_updateValue(packet, LeftMotor, -maxPower);
                    RDTPPacket_updateValue(packet, RightMotor, maxPower);
                } else {
                    RDTPPacket_updateValue(packet, LeftMotor, 0);
                    RDTPPacket_updateValue(packet, RightMotor, 0);
                }
            } else if (value) {
                RDTPPacket_updateValue(packet, LeftMotor, maxPower);
                RDTPPacket_updateValue(packet, RightMotor, -maxPower);
            } else {
                RDTPPacket_updateValue(packet, LeftMotor, 0);
                RDTPPacket_updateValue(packet, RightMotor, 0);
            }
            return;
            
        case XBoxButton:
            if (value) {
                if (maxPower == MediumMaxPower) {
                    maxPower = BurstMaxPower;
                } else {
                    maxPower = MediumMaxPower;
                }
            }
            return;
            
        case StartButton:
            if (value) {
                if (maxPower == MediumMaxPower) {
                    maxPower = SmallMaxPower;
                } else {
                    maxPower = MediumMaxPower;
                }
            }
            return;
            
        default:
            return;
    }
    
    if (max) {
        int8_t rightMotor;
        int8_t leftMotor;
        if (lastLeftXValue > 0) {
            leftMotor = max;
            rightMotor = (max * (GAMEPAD_MAX - lastLeftXValue)) / GAMEPAD_MAX;
        } else if (lastLeftXValue < 0) {
            leftMotor = (max * (GAMEPAD_MAX + lastLeftXValue)) / GAMEPAD_MAX;
            rightMotor = max;
        } else {
            leftMotor = max;
            rightMotor = max;
        }
        RDTPPacket_updateValue(packet, LeftMotor, leftMotor);
        RDTPPacket_updateValue(packet, RightMotor, rightMotor);
    } else {
        RDTPPacket_updateValue(packet, LeftMotor, 0);
        RDTPPacket_updateValue(packet, RightMotor, 0);
    }
    
    return;
}

- (void)updatePacket
{
    for (ServoLimitter *limitter in limitters) {
        [limitter update];
    }
}

@end
