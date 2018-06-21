#import "StickConverter.h"
#import "GamepadController.h"
#import "ServoLimitter.h"
#import "ServoAssignment.h"

#define degToDynamixelAngle(deg) (1024.0 / 90 * (deg) * 20 / 17)

static const int StickThreshold = 300;
static const int ServoStickThreshold = 8000;

@implementation StickConverter
{
    int lastLeftXValue;
    int max;
    RDTPPacket *packet;
    int maxPower;
    NSArray<ServoLimitter *> *limitters;
    RDTPPacketComponent servoToMoveWithLeftY;
    RDTPPacketComponent servoToMoveWithLeftX;
    RDTPPacketComponent servoToMoveWithRightX;
    RDTPPacketComponent servoToMoveWithRightY;
    BOOL isRBPressed;
    BOOL isLBPressed;
    BOOL isXBoxPressed;
    BOOL isRotating;
    int rotateDirection;
    int32_t initialPositions[10];
}

- (instancetype)initWithRDTPPacket:(RDTPPacket *)aPacket initialFlipperPositions:(int32_t *)positions
{
    if (self = [super init]) {
        lastLeftXValue = 0;
        max = 0;
        maxPower = INT8_MAX;
        packet = aPacket;
        self.shouldFlip = NO;
        servoToMoveWithLeftY = 0;
        servoToMoveWithLeftX = 0;
        servoToMoveWithRightX = 0;
        servoToMoveWithRightY = 0;
        isRBPressed = NO;
        isLBPressed = NO;
        isXBoxPressed = NO;
        rotateDirection = 0;
//        memcpy(initialPositions, positions, sizeof(int32_t) * 10);
        for (int i = 0; i < 10; ++i) {
            initialPositions[i] = positions[i];
        }
        
        NSMutableArray<ServoLimitter *> *mutableLimitters = [NSMutableArray new];
        for (RDTPPacketComponent i = Servo0; i <= Servo9; ++i) {
            ServoLimitter *limitter = [[ServoLimitter alloc] initWithServo:i packet:packet];
            limitter.currentValue = positions[i - Servo0];
            [mutableLimitters addObject:limitter];
        }
        limitters = mutableLimitters;
        limitters[ArmPitchHighAxis - Servo0].upperLimit = 755;
        limitters[ArmRollAxis - Servo0].lowerLimit = -1500;
        limitters[ArmRollAxis - Servo0].upperLimit = 1500;
        limitters[ArmGrabber - Servo0].lowerLimit = -630;
        limitters[ArmGrabber - Servo0].upperLimit = 380;
        limitters[ArmYawAxis - Servo0].upperLimit = 3046;
        limitters[ArmYawAxis - Servo0].lowerLimit = 1080;
        limitters[ArmPitchLowAxis - Servo0].upperLimit = 2087;
        limitters[ArmPitchLowAxis - Servo0].lowerLimit = 30;
        limitters[ArmPitchMidAxis - Servo0].upperLimit = 3497;
        limitters[ArmPitchMidAxis - Servo0].lowerLimit = 2032;
        limitters[LeftFrontFlipper - Servo0].shouldInvert = YES;
        limitters[RightBackFlipper - Servo0].shouldInvert = YES;
        limitters[ArmPitchLowAxis - Servo0].shouldInvert = YES;
        limitters[RightFrontFlipper - Servo0].divScale = 0.5;
        limitters[LeftFrontFlipper - Servo0].divScale = 0.5;
        limitters[LeftBackFlipper - Servo0].divScale = 0.5;
        limitters[RightBackFlipper - Servo0].divScale = 0.5;
//        limitters[ArmPitchHighAxis - Servo0].divScale = 20;
//        limitters[ArmRollAxis - Servo0].divScale = 20;
//        limitters[ArmGrabber - Servo0].divScale = 20;
        limitters[ArmYawAxis - Servo0].divScale = 2;
        limitters[ArmPitchLowAxis - Servo0].divScale = 2;
        limitters[ArmPitchMidAxis - Servo0].divScale = 2;
    }
    return self;
}

- (void)gamepad:(GamepadController *)gamepad updateValue:(int)value forStickAxis:(GamepadStickAxis)stick
{
    switch (stick) {
            
        case YButton:
            if (self.shouldFlip) {
                if (value) {
                    servoToMoveWithLeftY |= 1 << LeftBackFlipper;
                } else {
                    servoToMoveWithLeftY &= ~(1 << LeftBackFlipper);
                    [limitters[LeftBackFlipper - Servo0] updateStep:0];
                }
            } else {
                if (value) {
                    servoToMoveWithLeftY |= 1 << RightFrontFlipper;
                } else {
                    servoToMoveWithLeftY &= ~(1 << RightFrontFlipper);
                    [limitters[RightFrontFlipper - Servo0] updateStep:0];
                }
            }
            return;
            
        case BButton:
            if (self.shouldFlip) {
                if (value) {
                    servoToMoveWithLeftY |= 1 << LeftFrontFlipper;
                } else {
                    servoToMoveWithLeftY &= ~(1 << LeftFrontFlipper);
                    [limitters[LeftFrontFlipper - Servo0] updateStep:0];
                }
            } else {
                if (value) {
                    servoToMoveWithLeftY |= 1 << RightBackFlipper;
                } else {
                    servoToMoveWithLeftY &= ~(1 << RightBackFlipper);
                    [limitters[RightBackFlipper - Servo0] updateStep:0];
                }
            }
            return;
            
        case XButton:
            if (self.shouldFlip) {
                if (value) {
                    servoToMoveWithLeftY |= 1 << RightBackFlipper;
                } else {
                    servoToMoveWithLeftY &= ~(1 << RightBackFlipper);
                    [limitters[RightBackFlipper - Servo0] updateStep:0];
                }
            } else {
                if (value) {
                    servoToMoveWithLeftY |= 1 << LeftFrontFlipper;
                } else {
                    servoToMoveWithLeftY &= ~(1 << LeftFrontFlipper);
                    [limitters[LeftFrontFlipper - Servo0] updateStep:0];
                }
            }
            return;
            
        case AButton:
            if (self.shouldFlip) {
                if (value) {
                    servoToMoveWithLeftY |= 1 << RightFrontFlipper;
                } else {
                    servoToMoveWithLeftY &= ~(1 << RightFrontFlipper);
                    [limitters[RightFrontFlipper - Servo0] updateStep:0];
                }
            } else {
                if (value) {
                    servoToMoveWithLeftY |= 1 << LeftBackFlipper;
                } else {
                    servoToMoveWithLeftY &= ~(1 << LeftBackFlipper);
                    [limitters[LeftBackFlipper - Servo0] updateStep:0];
                }
            }
            return;
            
        case RightStickX:
            if (isRBPressed || isLBPressed) {
                if (self.shouldFlip) value = -value;
                if (abs(value) < ServoStickThreshold) value = 0;
                for (int i = Servo0; i <= Servo9; ++i) {
                    if (servoToMoveWithRightX & (1 << i)) {
                        [limitters[i - Servo0] updateStep:value];
                    }
                }
            } else {
                if (abs(value) < StickThreshold) {
                    RDTPPacket_updateValue(packet, LeftMotor, 0);
                    RDTPPacket_updateValue(packet, RightMotor, 0);
                } else {
                    double power = ((double)maxPower * value) / GAMEPAD_MAX;
                    RDTPPacket_updateValue(packet, LeftMotor, power);
                    RDTPPacket_updateValue(packet, RightMotor, -power);
                }
            }
            return;
            
        case RightStickY:
            if (abs(value) < ServoStickThreshold) value = 0;
            for (int i = Servo0; i <= Servo9; ++i) {
                if (servoToMoveWithRightY & (1 << i)) {
                    [limitters[i - Servo0] updateStep:value];
                }
            }
            return;
            
        case Pov:
            switch (value) {
                case -1:
                    rotateDirection = 0;
                    [limitters[ArmPitchMidAxis - Servo0] updateStep:0];
                    [limitters[ArmGrabber - Servo0] updateStep:0];
                    RDTPPacket_updateValue(packet, EnableServo, (1 << ArmPitchLowAxis) | (1 << ArmPitchMidAxis));
                    break;
                    
                case 0:
                    if (isRBPressed) {
                        [limitters[ArmPitchMidAxis - Servo0] updateStep:GAMEPAD_MAX / 2];
                    }
                    if (isLBPressed) {
                        [limitters[ArmGrabber - Servo0] updateStep:GAMEPAD_MAX / 2];
                    }
                    break;
                    
                case 9000:
                    rotateDirection = 1;
                    break;
                    
                case 18000:
                    if (isRBPressed) {
                        [limitters[ArmPitchMidAxis - Servo0] updateStep:GAMEPAD_MIN / 2];
                    }
                    if (isLBPressed) {
                        [limitters[ArmGrabber - Servo0] updateStep:GAMEPAD_MIN / 2];
                    }
                    break;
                    
                case 27000:
                    rotateDirection = -1;
                    if (isRBPressed) {
                        [limitters[ArmPitchLowAxis - Servo0] presetToAngle:1622];
                        [limitters[ArmPitchMidAxis - Servo0] presetToAngle:2761];
                        [limitters[ArmPitchHighAxis - Servo0] presetToAngle:-607];
                        [limitters[ArmRollAxis - Servo0] presetToAngle:-1216];
                    }
                    break;
                    
                default:
                    break;
            }
            return;
            
        case LeftStickY:
            if (abs(value) < ServoStickThreshold) value = 0;
            for (int i = Servo0; i <= Servo9; ++i) {
                if (servoToMoveWithLeftY & (1 << i)) {
                    [limitters[i - Servo0] updateStep:value];
                }
            }
            return;
            
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
            if (abs(value) < StickThreshold) value = 0;
            if (self.shouldFlip) {
                lastLeftXValue = -value;
            } else {
                lastLeftXValue = value;
            }
            if (abs(value) < ServoStickThreshold) value = 0;
            for (int i = Servo0; i <= Servo9; ++i) {
                if (servoToMoveWithLeftX & (1 << i)) {
                    [limitters[i - Servo0] updateStep:value];
                }
            }
            break;
            
        case RightTriggerButton:
            isRBPressed = value;
            if (value) {
                servoToMoveWithRightX |= 1 << ArmYawAxis;
                servoToMoveWithRightY |= 1 << ArmPitchLowAxis;
            } else {
                servoToMoveWithRightX &= ~(1 << ArmYawAxis);
                servoToMoveWithRightY &= ~(1 << ArmPitchLowAxis);
                [limitters[ArmYawAxis - Servo0] updateStep:0];
                [limitters[ArmPitchLowAxis - Servo0] updateStep:0];
                [limitters[ArmPitchMidAxis - Servo0] updateStep:0];
            }
            return;
        
        case LeftTriggerButton:
            isLBPressed = value;
            if (value) {
                servoToMoveWithRightY |= 1 << ArmPitchHighAxis;
                servoToMoveWithRightX |= 1 << ArmRollAxis;
            } else {
                servoToMoveWithRightY &= ~(1 << ArmPitchHighAxis);
                servoToMoveWithRightX &= ~(1 << ArmRollAxis);
            }
            return;
            
        case RightStickButton:
            [limitters[RightFrontFlipper - Servo0] presetToAngle:initialPositions[RightFrontFlipper - Servo0]];
            [limitters[LeftFrontFlipper - Servo0] presetToAngle:initialPositions[LeftFrontFlipper - Servo0]];
            [limitters[LeftBackFlipper - Servo0] presetToAngle:initialPositions[LeftBackFlipper - Servo0]];
            [limitters[RightBackFlipper - Servo0] presetToAngle:initialPositions[RightBackFlipper - Servo0]];
            return;
            
        case XBoxButton:
            isXBoxPressed = value;
            if (value && ! isRotating) {
                isRotating = YES;
            } else {
                return;
            }
            limitters[RightFrontFlipper - Servo0].divScale = 0.3;
            limitters[LeftFrontFlipper - Servo0].divScale = 0.3;
            limitters[LeftBackFlipper - Servo0].divScale = 0.3;
            limitters[RightBackFlipper - Servo0].divScale = 0.3;
            if (rotateDirection == 0) {
                const double presetAngle = degToDynamixelAngle(180);
                [limitters[RightFrontFlipper - Servo0] presetToAngle:initialPositions[RightFrontFlipper - Servo0]];
                [limitters[LeftFrontFlipper - Servo0] presetToAngle:initialPositions[LeftFrontFlipper - Servo0] - presetAngle];
                [limitters[LeftBackFlipper - Servo0] presetToAngle:initialPositions[LeftBackFlipper - Servo0]];
                [limitters[RightBackFlipper - Servo0] presetToAngle:initialPositions[RightBackFlipper - Servo0] - presetAngle];
                return;
            }
            /* fallthrough */
            
        case LeftStickButton:
        {
            const double presetAngle = degToDynamixelAngle(90);
            [limitters[RightFrontFlipper - Servo0] presetToAngle:initialPositions[RightFrontFlipper - Servo0] + presetAngle];
            [limitters[LeftFrontFlipper - Servo0] presetToAngle:initialPositions[LeftFrontFlipper - Servo0] - presetAngle];
            [limitters[LeftBackFlipper - Servo0] presetToAngle:initialPositions[LeftBackFlipper - Servo0] + presetAngle];
            [limitters[RightBackFlipper - Servo0] presetToAngle:initialPositions[RightBackFlipper - Servo0] - presetAngle];
        }
            return;
        
            
        case SelectButton:
            RDTPPacket_setCommand(packet, RebootServo);
            return;
            
        case StartButton:
            [limitters[ArmYawAxis - Servo0] presetToAngle:initialPositions[ArmYawAxis - Servo0]];
            [limitters[ArmPitchLowAxis - Servo0] presetToAngle:initialPositions[ArmPitchLowAxis - Servo0]];
            [limitters[ArmPitchMidAxis - Servo0] presetToAngle:initialPositions[ArmPitchMidAxis - Servo0]];
            [limitters[ArmPitchHighAxis - Servo0] presetToAngle:initialPositions[ArmPitchHighAxis - Servo0]];
            [limitters[ArmRollAxis - Servo0] presetToAngle:initialPositions[ArmRollAxis - Servo0]];
            [limitters[ArmGrabber - Servo0] presetToAngle:initialPositions[ArmGrabber - Servo0]];
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
    if (isRotating) {
        if (! ([limitters[RightFrontFlipper - Servo0] update]
            | [limitters[LeftFrontFlipper - Servo0] update]
            | [limitters[LeftBackFlipper - Servo0] update]
            | [limitters[RightBackFlipper - Servo0] update])) {
            const double deg90 = degToDynamixelAngle(90);
            if (isXBoxPressed) {
                switch (rotateDirection) {
                    case 0:
                    {
                        const double rotateAngle = degToDynamixelAngle(360);
                        [limitters[RightFrontFlipper - Servo0] presetToAngle:initialPositions[RightFrontFlipper - Servo0] - rotateAngle];
                        [limitters[LeftFrontFlipper - Servo0] presetToAngle:initialPositions[LeftFrontFlipper - Servo0] + rotateAngle - deg90 - deg90];
                        [limitters[LeftBackFlipper - Servo0] presetToAngle:initialPositions[LeftBackFlipper - Servo0]  + rotateAngle];
                        [limitters[RightBackFlipper - Servo0] presetToAngle:initialPositions[RightBackFlipper - Servo0] - rotateAngle - deg90 - deg90];
                        
                        initialPositions[RightFrontFlipper - Servo0] = limitters[RightFrontFlipper - Servo0].currentValue - rotateAngle;
                        initialPositions[LeftFrontFlipper - Servo0] = limitters[LeftFrontFlipper - Servo0].currentValue + rotateAngle + deg90 + deg90;
                        initialPositions[LeftBackFlipper - Servo0] = limitters[LeftBackFlipper - Servo0].currentValue + rotateAngle;
                        initialPositions[RightBackFlipper - Servo0] = limitters[RightBackFlipper - Servo0].currentValue - rotateAngle + deg90 + deg90;
                        break;
                    }
                        
                    case 1:
                    {
                        const double rotateAngle = degToDynamixelAngle(360);
                        [limitters[LeftFrontFlipper - Servo0] presetToAngle:initialPositions[LeftFrontFlipper - Servo0] - deg90 + rotateAngle];
                        [limitters[LeftBackFlipper - Servo0] presetToAngle:initialPositions[LeftBackFlipper - Servo0] + deg90 + rotateAngle];
                        initialPositions[LeftFrontFlipper - Servo0] = limitters[LeftFrontFlipper - Servo0].currentValue + deg90 + rotateAngle;
                        initialPositions[LeftBackFlipper - Servo0] = limitters[LeftBackFlipper - Servo0].currentValue - deg90 + rotateAngle;
                    }
                        break;
                        
                    case -1:
                    {
                        const double rotateAngle = degToDynamixelAngle(360);
                        [limitters[RightFrontFlipper - Servo0] presetToAngle:initialPositions[RightFrontFlipper - Servo0] + deg90 - rotateAngle];
                        [limitters[RightBackFlipper - Servo0] presetToAngle:initialPositions[RightBackFlipper - Servo0] - deg90 - rotateAngle];
                        initialPositions[RightFrontFlipper - Servo0] = limitters[RightFrontFlipper - Servo0].currentValue - deg90 - rotateAngle;
                        initialPositions[RightBackFlipper - Servo0] = limitters[RightBackFlipper - Servo0].currentValue + deg90 - rotateAngle;
                    }
                        break;
                        
                    default:
                        break;
                }
                rotateDirection *= -1;
            } else {
                isRotating = NO;
                limitters[RightFrontFlipper - Servo0].divScale = 0.5;
                limitters[LeftFrontFlipper - Servo0].divScale = 0.5;
                limitters[LeftBackFlipper - Servo0].divScale = 0.5;
                limitters[RightBackFlipper - Servo0].divScale = 0.5;
            }
        }
    } else {
        for (ServoLimitter *limitter in limitters) {
            [limitter update];
        }
    }
}

- (void)frontPreset
{
    [limitters[ArmPitchHighAxis - Servo0] presetToAngle:initialPositions[ArmPitchHighAxis - Servo0]];
    [limitters[ArmRollAxis - Servo0] presetToAngle:initialPositions[ArmRollAxis - Servo0]];
    [limitters[ArmGrabber - Servo0] presetToAngle:initialPositions[ArmGrabber - Servo0]];
    [limitters[ArmYawAxis - Servo0] presetToAngle:initialPositions[ArmYawAxis - Servo0]];
    [limitters[ArmPitchLowAxis - Servo0] presetToAngle:initialPositions[ArmPitchLowAxis - Servo0]];
    [limitters[ArmPitchMidAxis - Servo0] presetToAngle:initialPositions[ArmPitchMidAxis - Servo0]];
}

- (void)backPreset
{
    [limitters[ArmPitchHighAxis - Servo0] presetToAngle:initialPositions[ArmPitchHighAxis - Servo0]];
    [limitters[ArmRollAxis - Servo0] presetToAngle:initialPositions[ArmRollAxis - Servo0]];
    [limitters[ArmGrabber - Servo0] presetToAngle:initialPositions[ArmGrabber - Servo0]];
    [limitters[ArmYawAxis - Servo0] presetToAngle:initialPositions[ArmYawAxis - Servo0]];
    [limitters[ArmPitchLowAxis - Servo0] presetToAngle:2040];
    [limitters[ArmPitchMidAxis - Servo0] presetToAngle:2285];
}

- (void)resetPositionInformation:(int32_t)position forServo:(RDTPPacketComponent)servo
{
    limitters[servo - Servo0].currentValue = position;
}

@end
