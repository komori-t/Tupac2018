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
        [limitters[3] presetToAngle:0.0];
        [limitters[4] presetToAngle:0.0];
        [limitters[5] presetToAngle:0.0];
        [limitters[6] presetToAngle:0.0];
        [limitters[8] presetToAngle:180.0];
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
                servo |= 1 << Servo9;
            } else {
                servo &= ~(1 << Servo9);
                [limitters[9] updateStep:0];
            }
            return;
            
        case Pov:
            switch (value) {
                case -1:
                    servo &= ~((1 << Servo3) | (1 << Servo4) | (1 << Servo5) | (1 << Servo6) | (1 << Servo7) | (1 << Servo8));
                    break;
                    
                case 0:
                    servo &= ~((1 << Servo5) | (1 << Servo6) | (1 << Servo7) | (1 << Servo8));
                    servo |= (1 << Servo3) | (1 << Servo4);
                    break;
                    
                case 9000:
                    servo &= ~((1 << Servo3) | (1 << Servo4) | (1 << Servo7) | (1 << Servo8));
                    servo |= (1 << Servo5) | (1 << Servo6);
                    break;
                    
                case 18000:
                    servo &= ~((1 << Servo3) | (1 << Servo4) | (1 << Servo5) | (1 << Servo6) | (1 << Servo8));
                    servo |= 1 << Servo7;
                    break;
                    
                case 27000:
                    servo &= ~((1 << Servo3) | (1 << Servo4) | (1 << Servo5) | (1 << Servo6) | (1 << Servo7));
                    servo |= 1 << Servo8;
                    break;
                    
                default:
                    break;
            }
            break;
            
        case LeftStickY:
        {
            int8_t angle = scale(value, GAMEPAD_MAX, INT8_MAX);
            for (int i = Servo0; i <= Servo9; ++i) {
                if (servo & (1 << i)) {
                    [limitters[i - Servo0] updateStep:angle];
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
